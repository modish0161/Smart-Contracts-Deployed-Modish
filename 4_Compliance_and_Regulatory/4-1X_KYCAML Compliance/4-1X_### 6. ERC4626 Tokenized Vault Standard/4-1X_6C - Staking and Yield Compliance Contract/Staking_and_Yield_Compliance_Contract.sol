// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract StakingAndYieldComplianceVault is ERC4626, Ownable, AccessControl, Pausable {
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");

    struct Staker {
        uint256 balance;
        uint256 rewards;
        bool compliant;
    }

    mapping(address => Staker) private stakers;
    uint256 public totalStaked;
    uint256 public rewardRate; // Rewards per block or time unit
    uint256 public lastUpdatedBlock;

    event ComplianceUpdated(address indexed user, bool complianceStatus);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        IERC20 _asset,
        string memory name_,
        string memory symbol_,
        address complianceOfficer,
        uint256 _rewardRate
    ) ERC4626(_asset) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, complianceOfficer);

        rewardRate = _rewardRate;
        lastUpdatedBlock = block.number;

        _setMetadata(name_, symbol_);
    }

    modifier updateRewards(address user) {
        if (stakers[user].balance > 0) {
            stakers[user].rewards += _calculateRewards(user);
        }
        lastUpdatedBlock = block.number;
        _;
    }

    function setComplianceStatus(address user, bool status) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        stakers[user].compliant = status;
        emit ComplianceUpdated(user, status);
    }

    function _calculateRewards(address user) internal view returns (uint256) {
        return stakers[user].balance * (block.number - lastUpdatedBlock) * rewardRate;
    }

    function stake(uint256 amount) external whenNotPaused updateRewards(msg.sender) {
        require(stakers[msg.sender].compliant, "User not compliant");
        asset.transferFrom(msg.sender, address(this), amount);

        stakers[msg.sender].balance += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external whenNotPaused updateRewards(msg.sender) {
        require(stakers[msg.sender].balance >= amount, "Insufficient staked amount");
        stakers[msg.sender].balance -= amount;
        totalStaked -= amount;
        asset.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external whenNotPaused updateRewards(msg.sender) {
        require(stakers[msg.sender].compliant, "User not compliant");
        uint256 reward = stakers[msg.sender].rewards;
        require(reward > 0, "No rewards available");

        stakers[msg.sender].rewards = 0;
        asset.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateRewardRate(uint256 newRewardRate) external onlyRole(STAKING_MANAGER_ROLE) {
        rewardRate = newRewardRate;
    }

    function viewRewards(address user) external view returns (uint256) {
        return stakers[user].rewards + _calculateRewards(user);
    }

    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
