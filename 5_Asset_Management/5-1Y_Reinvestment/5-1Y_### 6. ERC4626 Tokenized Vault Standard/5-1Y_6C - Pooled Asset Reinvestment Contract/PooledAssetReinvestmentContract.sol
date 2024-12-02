// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PooledAssetReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    ERC4626 public vault;
    IERC20 public assetToken;
    address[] public supportedVaults;
    mapping(address => uint256) public userShares;
    mapping(address => uint256) public reinvestmentStrategy; // Maps user address to vault index for reinvestment

    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);
    event Reinvested(address indexed user, uint256 amount, uint256 shares);
    event StrategyUpdated(address indexed user, uint256 vaultIndex);
    event VaultAdded(address indexed vault);

    constructor(address _vaultAddress) {
        require(_vaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(_vaultAddress);
        assetToken = IERC20(vault.asset());
        supportedVaults.push(_vaultAddress); // Add initial vault to supported list
    }

    // Function to deposit assets into the vault
    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(assetToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Approve and deposit into vault
        assetToken.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, address(this));
        
        userShares[msg.sender] = userShares[msg.sender].add(shares);

        emit Deposited(msg.sender, amount, shares);
    }

    // Function to withdraw assets from the vault
    function withdraw(uint256 shares) external whenNotPaused nonReentrant {
        require(userShares[msg.sender] >= shares, "Insufficient shares");

        userShares[msg.sender] = userShares[msg.sender].sub(shares);
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Function to set reinvestment strategy
    function setReinvestmentStrategy(uint256 vaultIndex) external whenNotPaused {
        require(vaultIndex < supportedVaults.length, "Invalid vault index");
        reinvestmentStrategy[msg.sender] = vaultIndex;

        emit StrategyUpdated(msg.sender, vaultIndex);
    }

    // Function to reinvest yield into selected vault based on strategy
    function reinvestYield() external whenNotPaused nonReentrant {
        uint256 totalShares = userShares[msg.sender];
        require(totalShares > 0, "No shares deposited");

        uint256 availableAssets = vault.previewRedeem(totalShares);
        uint256 reinvestmentAmount = availableAssets.mul(10).div(100); // Example: reinvest 10% of yield
        address targetVault = supportedVaults[reinvestmentStrategy[msg.sender]];

        // Withdraw yield from original vault
        vault.redeem(reinvestmentAmount, address(this), address(this));

        // Approve and deposit yield into target vault
        assetToken.approve(targetVault, reinvestmentAmount);
        ERC4626(targetVault).deposit(reinvestmentAmount, address(this));

        // Update user shares for the target vault
        uint256 newShares = ERC4626(targetVault).convertToShares(reinvestmentAmount);
        userShares[msg.sender] = userShares[msg.sender].add(newShares);

        emit Reinvested(msg.sender, reinvestmentAmount, newShares);
    }

    // Function to add a new vault to the supported vault list
    function addVault(address newVault) external onlyOwner {
        require(newVault != address(0), "Invalid vault address");
        supportedVaults.push(newVault);

        emit VaultAdded(newVault);
    }

    // Emergency withdrawal for users in case of a contract malfunction
    function emergencyWithdraw() external nonReentrant {
        uint256 shares = userShares[msg.sender];
        require(shares > 0, "No shares to withdraw");

        userShares[msg.sender] = 0;
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Function to pause the contract in case of an emergency
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to update the main vault address
    function updateVault(address newVaultAddress) external onlyOwner {
        require(newVaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(newVaultAddress);
        assetToken = IERC20(vault.asset());
    }
}
