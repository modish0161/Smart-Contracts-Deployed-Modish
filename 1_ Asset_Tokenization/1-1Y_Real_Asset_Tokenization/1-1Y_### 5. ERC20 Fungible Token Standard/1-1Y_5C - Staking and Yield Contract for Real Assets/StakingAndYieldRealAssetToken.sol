// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Staking and Yield Contract for Real Assets
/// @notice Allows token holders to stake their shares of real assets and earn yield, such as rental income or commodity dividends.
/// @dev Implements ERC20 standard with additional staking and yield functionalities.
contract StakingAndYieldRealAssetToken is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Role for managing staking and yield
    bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");

    // Struct to store staking details
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 reward;
    }

    // Mapping of staker address to their stakes
    mapping(address => Stake) private _stakes;

    // Annual percentage yield (APY) rate for staking
    uint256 public apyRate;
    
    // Reward distribution duration (e.g., 1 year = 31536000 seconds)
    uint256 public rewardDuration;

    // Total staked tokens
    uint256 private _totalStaked;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 startTime);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    /// @dev Constructor to set token details and initial APY rate
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialSupply Initial supply of tokens
    /// @param _apyRate Initial APY rate for staking
    /// @param _rewardDuration Reward distribution duration in seconds
    constructor(string memory name, string memory symbol, uint256 initialSupply, uint256 _apyRate, uint256 _rewardDuration) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAKING_MANAGER_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
        apyRate = _apyRate;
        rewardDuration = _rewardDuration;
    }

    /// @notice Stake tokens to earn yield
    /// @param amount Number of tokens to stake
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0 tokens");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        _stakes[msg.sender].amount = _stakes[msg.sender].amount.add(amount);
        _stakes[msg.sender].startTime = block.timestamp;

        _burn(msg.sender, amount);
        _totalStaked = _totalStaked.add(amount);

        emit Staked(msg.sender, amount, block.timestamp);
    }

    /// @notice Unstake tokens and claim rewards
    function unstake() external nonReentrant whenNotPaused {
        require(_stakes[msg.sender].amount > 0, "No tokens to unstake");

        uint256 stakedAmount = _stakes[msg.sender].amount;
        uint256 reward = calculateReward(msg.sender);

        _mint(msg.sender, stakedAmount.add(reward));
        _totalStaked = _totalStaked.sub(stakedAmount);

        emit Unstaked(msg.sender, stakedAmount, reward);

        delete _stakes[msg.sender];
    }

    /// @notice Calculate staking reward based on staked amount and duration
    /// @param staker Address of the staker
    /// @return reward The calculated reward for the staker
    function calculateReward(address staker) public view returns (uint256 reward) {
        Stake memory stakeData = _stakes[staker];
        if (stakeData.amount == 0) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp.sub(stakeData.startTime);
        reward = stakeData.amount.mul(apyRate).mul(stakingDuration).div(rewardDuration).div(100);
    }

    /// @notice Claim staking rewards without unstaking
    function claimReward() external nonReentrant whenNotPaused {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward available");

        _stakes[msg.sender].reward = _stakes[msg.sender].reward.add(reward);
        _stakes[msg.sender].startTime = block.timestamp;

        _mint(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    /// @notice Change the APY rate for staking
    /// @param newRate New APY rate (in percentage)
    /// @dev Only callable by STAKING_MANAGER_ROLE
    function setAPYRate(uint256 newRate) external onlyRole(STAKING_MANAGER_ROLE) {
        require(newRate > 0, "APY rate must be greater than 0");
        apyRate = newRate;
    }

    /// @notice Change the reward duration
    /// @param newDuration New reward distribution duration (in seconds)
    /// @dev Only callable by STAKING_MANAGER_ROLE
    function setRewardDuration(uint256 newDuration) external onlyRole(STAKING_MANAGER_ROLE) {
        require(newDuration > 0, "Reward duration must be greater than 0");
        rewardDuration = newDuration;
    }

    /// @notice Pause the contract
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Get the staking details of an address
    /// @param staker Address of the staker
    /// @return amount The staked amount
    /// @return startTime The start time of staking
    /// @return reward The accumulated reward
    function getStakeDetails(address staker) external view returns (uint256 amount, uint256 startTime, uint256 reward) {
        Stake memory stakeData = _stakes[staker];
        return (stakeData.amount, stakeData.startTime, stakeData.reward);
    }

    /// @notice Total amount of staked tokens
    /// @return totalStaked The total amount of tokens staked in the contract
    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}