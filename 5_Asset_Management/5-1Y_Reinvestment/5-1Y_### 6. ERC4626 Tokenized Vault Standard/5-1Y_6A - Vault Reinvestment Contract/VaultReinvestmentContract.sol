// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VaultReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    ERC4626 public vault;
    IERC20 public assetToken;
    mapping(address => uint256) public depositedShares;
    mapping(address => uint256) public reinvestmentPercentages;

    event Deposited(address indexed investor, uint256 amount, uint256 shares);
    event Withdrawn(address indexed investor, uint256 shares, uint256 amount);
    event Reinvested(address indexed investor, uint256 amount, uint256 shares);
    event ReinvestmentPercentageUpdated(address indexed investor, uint256 percentage);

    constructor(address _vaultAddress) {
        require(_vaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(_vaultAddress);
        assetToken = IERC20(vault.asset());
    }

    // Deposit assets into the vault
    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(assetToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Approve and deposit into vault
        assetToken.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, address(this));
        
        depositedShares[msg.sender] = depositedShares[msg.sender].add(shares);

        emit Deposited(msg.sender, amount, shares);
    }

    // Withdraw assets from the vault
    function withdraw(uint256 shares) external whenNotPaused nonReentrant {
        require(depositedShares[msg.sender] >= shares, "Insufficient shares");

        depositedShares[msg.sender] = depositedShares[msg.sender].sub(shares);
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Set reinvestment percentage
    function setReinvestmentPercentage(uint256 percentage) external whenNotPaused {
        require(percentage <= 100, "Percentage cannot exceed 100");

        reinvestmentPercentages[msg.sender] = percentage;

        emit ReinvestmentPercentageUpdated(msg.sender, percentage);
    }

    // Reinvest profits based on reinvestment percentage
    function reinvestProfits() external whenNotPaused nonReentrant {
        uint256 totalShares = depositedShares[msg.sender];
        require(totalShares > 0, "No shares deposited");

        uint256 availableAssets = vault.previewRedeem(totalShares);
        uint256 reinvestmentAmount = availableAssets.mul(reinvestmentPercentages[msg.sender]).div(100);
        uint256 sharesToReinvest = vault.deposit(reinvestmentAmount, address(this));

        depositedShares[msg.sender] = depositedShares[msg.sender].add(sharesToReinvest);

        emit Reinvested(msg.sender, reinvestmentAmount, sharesToReinvest);
    }

    // Emergency withdraw all assets for the user
    function emergencyWithdraw() external nonReentrant {
        uint256 shares = depositedShares[msg.sender];
        require(shares > 0, "No shares to withdraw");

        depositedShares[msg.sender] = 0;
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Pause the contract in case of emergency
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Update the vault address
    function updateVault(address newVaultAddress) external onlyOwner {
        require(newVaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(newVaultAddress);
        assetToken = IERC20(vault.asset());
    }
}
