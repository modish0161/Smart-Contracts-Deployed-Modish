// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract RedemptionMutualFund is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REDEMPTION_AGENT_ROLE = keccak256("REDEMPTION_AGENT_ROLE");

    // Total assets under management in the contract (denominated in ETH for simplicity)
    uint256 public totalAssets;

    // Mapping to track the redemption requests
    mapping(address => uint256) public redemptionRequests;

    event RedemptionRequested(address indexed investor, uint256 tokenAmount);
    event RedemptionProcessed(address indexed investor, uint256 tokenAmount, uint256 assetValue);
    event AssetsDeposited(uint256 amount);

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
        _setupRole(REDEMPTION_AGENT_ROLE, msg.sender);
    }

    // Function to deposit assets into the fund
    function depositAssets() external payable onlyRole(ADMIN_ROLE) {
        require(msg.value > 0, "Amount must be greater than 0");
        totalAssets = totalAssets.add(msg.value);
        emit AssetsDeposited(msg.value);
    }

    // Request redemption of mutual fund tokens for underlying assets
    function requestRedemption(uint256 tokenAmount) external nonReentrant whenNotPaused {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        require(tokenAmount > 0, "Token amount must be greater than 0");

        // Burn the tokens from the investor
        _burn(msg.sender, tokenAmount, "", "");

        // Record the redemption request
        redemptionRequests[msg.sender] = redemptionRequests[msg.sender].add(tokenAmount);

        emit RedemptionRequested(msg.sender, tokenAmount);
    }

    // Process redemption requests and transfer proportional assets to the investors
    function processRedemption(address investor) external nonReentrant onlyRole(REDEMPTION_AGENT_ROLE) {
        uint256 tokenAmount = redemptionRequests[investor];
        require(tokenAmount > 0, "No redemption request found");

        // Calculate the proportional asset value
        uint256 assetValue = totalAssets.mul(tokenAmount).div(totalSupply());

        // Update the state
        totalAssets = totalAssets.sub(assetValue);
        redemptionRequests[investor] = 0;

        // Transfer the assets to the investor
        payable(investor).transfer(assetValue);

        emit RedemptionProcessed(investor, tokenAmount, assetValue);
    }

    // Get the proportional value of the assets for a specific token amount
    function getProportionalAssetValue(uint256 tokenAmount) public view returns (uint256) {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        return totalAssets.mul(tokenAmount).div(totalSupply());
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Transfer ownership override to ensure role setup for new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(REDEMPTION_AGENT_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Emergency function to withdraw all funds (Owner only)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(balance);
    }
}
