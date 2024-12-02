// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract DividendAndYieldDistribution is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    uint256 public totalDividends; // Total dividends available for distribution
    uint256 public lastDistributionTimestamp; // Last time dividends were distributed

    // Events
    event DividendsDistributed(uint256 totalAmount);
    event DividendsWithdrawn(address indexed investor, uint256 amount);
    event YieldDeposited(address indexed from, uint256 amount);

    // Mapping to keep track of dividends claimed by investors
    mapping(address => uint256) public dividendsClaimed;

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC1400(name, symbol, new address )
    {
        _mint(msg.sender, initialSupply, "", "");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
    }

    // Function to deposit yield into the contract for distribution
    function depositYield() external payable onlyRole(DISTRIBUTOR_ROLE) nonReentrant {
        require(msg.value > 0, "Yield amount must be greater than 0");
        totalDividends = totalDividends.add(msg.value);
        emit YieldDeposited(msg.sender, msg.value);
    }

    // Function to distribute dividends to all token holders
    function distributeDividends() external onlyRole(DISTRIBUTOR_ROLE) nonReentrant {
        require(totalDividends > 0, "No dividends available for distribution");

        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No tokens in circulation");

        uint256 totalDistributed = 0;

        // Iterate through all token holders and distribute dividends proportionally
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            address investor = address(i);
            uint256 balance = balanceOf(investor);
            uint256 dividendShare = totalDividends.mul(balance).div(totalSupply);
            dividendsClaimed[investor] = dividendsClaimed[investor].add(dividendShare);
            totalDistributed = totalDistributed.add(dividendShare);
        }

        // Emit the distribution event
        emit DividendsDistributed(totalDistributed);

        // Update the last distribution timestamp
        lastDistributionTimestamp = block.timestamp;
    }

    // Function for investors to withdraw their dividends
    function withdrawDividends() external nonReentrant {
        uint256 withdrawableAmount = dividendsClaimed[msg.sender];
        require(withdrawableAmount > 0, "No dividends available for withdrawal");

        dividendsClaimed[msg.sender] = 0;
        totalDividends = totalDividends.sub(withdrawableAmount);

        payable(msg.sender).transfer(withdrawableAmount);
        emit DividendsWithdrawn(msg.sender, withdrawableAmount);
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Transfer Ownership Override
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(DISTRIBUTOR_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Emergency function to withdraw all funds (Owner only)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(balance);
    }
}
