// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingRedemptionReporting is ERC4626, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Regulatory Authority Address
    address public authorityAddress;

    // Minimum asset movement threshold for reporting
    uint256 public reportingThreshold;

    // Total staked and redeemed values
    uint256 public totalStaked;
    uint256 public totalRedeemed;

    // Events
    event StakingReported(uint256 stakedAmount, address indexed staker, uint256 timestamp);
    event RedemptionReported(uint256 redeemedAmount, address indexed redeemer, uint256 timestamp);
    event ReportSubmitted(uint256 totalStaked, uint256 totalRedeemed, uint256 timestamp);

    // Constructor to initialize the contract with parameters
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address _authorityAddress,
        uint256 _reportingThreshold
    ) ERC4626(asset, name, symbol) {
        require(_authorityAddress != address(0), "Invalid authority address");
        authorityAddress = _authorityAddress;
        reportingThreshold = _reportingThreshold;
    }

    // Function to set the reporting threshold
    function setReportingThreshold(uint256 _threshold) external onlyOwner {
        reportingThreshold = _threshold;
    }

    // Function to set the authority address
    function setAuthorityAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid authority address");
        authorityAddress = _address;
    }

    // Function to handle staking
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        
        totalStaked = totalStaked.add(amount);
        
        // Transfer the staked tokens to the contract
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        emit StakingReported(amount, msg.sender, block.timestamp);
        
        _checkForReporting();
    }

    // Function to handle redemption
    function redeem(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        
        totalRedeemed = totalRedeemed.add(amount);
        
        // Transfer the redeemed tokens back to the user
        asset.safeTransfer(msg.sender, amount);
        
        emit RedemptionReported(amount, msg.sender, block.timestamp);
        
        _checkForReporting();
    }

    // Internal function to check if reporting is required
    function _checkForReporting() internal {
        if (totalStaked >= reportingThreshold || totalRedeemed >= reportingThreshold) {
            _submitReport();
        }
    }

    // Internal function to submit a report to the regulatory authority
    function _submitReport() internal {
        emit ReportSubmitted(totalStaked, totalRedeemed, block.timestamp);
        
        // Reset the total values after reporting
        totalStaked = 0;
        totalRedeemed = 0;
    }

    // Function to deposit assets and mint vault tokens
    function deposit(uint256 assets, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    // Function to withdraw assets and burn vault tokens
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    // Function to pause the contract in emergencies
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
