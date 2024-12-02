// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DividendDistribution is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DIVIDEND_MANAGER_ROLE = keccak256("DIVIDEND_MANAGER_ROLE");

    uint256 public dividendPerToken; // Dividend amount in wei per token
    uint256 public totalDividendsDistributed;

    mapping(address => uint256) public lastDividendsClaimed;

    event DividendDeposited(uint256 amount);
    event DividendClaimed(address indexed account, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DIVIDEND_MANAGER_ROLE, msg.sender);
    }

    // Deposit dividends for distribution
    function depositDividends() external payable onlyRole(DIVIDEND_MANAGER_ROLE) {
        require(msg.value > 0, "No ether sent for dividends");
        dividendPerToken = dividendPerToken.add(msg.value.div(totalSupply()));
        totalDividendsDistributed = totalDividendsDistributed.add(msg.value);

        emit DividendDeposited(msg.value);
    }

    // Calculate dividends owed to an account
    function dividendsOwed(address account) public view returns (uint256) {
        uint256 owed = balanceOf(account).mul(dividendPerToken).sub(lastDividendsClaimed[account]);
        return owed;
    }

    // Claim dividends
    function claimDividends() external whenNotPaused nonReentrant {
        uint256 owed = dividendsOwed(msg.sender);
        require(owed > 0, "No dividends owed");

        lastDividendsClaimed[msg.sender] = lastDividendsClaimed[msg.sender].add(owed);
        payable(msg.sender).transfer(owed);

        emit DividendClaimed(msg.sender, owed);
    }

    // Withdraw any unclaimed dividends
    function withdrawUnclaimedDividends() external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");

        payable(owner()).transfer(balance);
    }

    // Pause and unpause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Fallback function to receive Ether
    receive() external payable {
        if (msg.value > 0) {
            depositDividends();
        }
    }
}
