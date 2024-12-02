// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Staking and Yield Contract for Tokenized Assets
/// @dev This contract allows holders of tokenized securities to stake their assets in a vault and earn yield.
///      It adheres to the ERC4626 standard for tokenized vaults, making it compatible with various tokenized assets.
contract StakingYieldVault is ERC4626, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Role definitions for access control
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant REWARD_MANAGER_ROLE = keccak256("REWARD_MANAGER_ROLE");

    // Reward token for yield distribution
    IERC20 public rewardToken;
    uint256 public rewardRate; // Reward rate per block

    // Mapping to store user rewards
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private lastUpdateBlock;

    // Events for logging
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardClaimed(address indexed user, uint256 reward);

    /// @notice Constructor to initialize the vault with underlying ERC20 token and reward token
    /// @param asset Address of the underlying ERC20 token (e.g., a stablecoin or security token)
    /// @param rewardTokenAddress Address of the reward token for yield distribution
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    constructor(
        IERC20 asset,
        IERC20 rewardTokenAddress,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {
        rewardToken = rewardTokenAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(REWARD_MANAGER_ROLE, msg.sender);
    }

    /// @notice Pauses all deposit, withdraw, and transfer actions
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpauses all deposit, withdraw, and transfer actions
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Updates the reward rate for yield distribution
    /// @dev Only accounts with the REWARD_MANAGER_ROLE can update the reward rate
    /// @param newRate New reward rate per block
    function updateRewardRate(uint256 newRate) external onlyRole(REWARD_MANAGER_ROLE) {
        uint256 oldRate = rewardRate;
        rewardRate = newRate;
        emit RewardRateUpdated(oldRate, newRate);
    }

    /// @notice Calculates and updates rewards for the user
    /// @param account The user account to update rewards for
    function _updateReward(address account) internal {
        if (account != address(0)) {
            rewards[account] = earned(account);
            lastUpdateBlock[account] = block.number;
        }
    }

    /// @notice Calculates the earned rewards for a user
    /// @param account The user account to calculate rewards for
    /// @return The amount of earned rewards
    function earned(address account) public view returns (uint256) {
        uint256 blocks = block.number - lastUpdateBlock[account];
        return rewards[account] + (balanceOf(account) * blocks * rewardRate) / 1e18;
    }

    /// @notice Claims the earned rewards for the caller
    function claimReward() external nonReentrant {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No reward to claim");
        rewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /// @notice Deposits assets into the vault
    /// @dev Overrides the deposit function from ERC4626 to add pausable and non-reentrant modifiers
    function deposit(uint256 assets, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        _updateReward(receiver);
        return super.deposit(assets, receiver);
    }

    /// @notice Withdraws assets from the vault
    /// @dev Overrides the withdraw function from ERC4626 to add pausable and non-reentrant modifiers
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        _updateReward(owner);
        return super.withdraw(assets, receiver, owner);
    }

    /// @notice Override _beforeTokenTransfer to include pausable functionality
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) whenNotPaused {
        _updateReward(from);
        _updateReward(to);
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @notice Override supportsInterface to include additional interfaces
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC4626) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
