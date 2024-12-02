// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VaultRegulatoryReporting is ERC4626, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Regulatory Authority Address
    address public authorityAddress;

    // Minimum threshold for reporting large inflows or outflows
    uint256 public reportingThreshold;

    // Events
    event ReportSubmitted(address indexed from, uint256 amount, string reportType, uint256 timestamp);

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

    // Function to deposit assets and mint vault tokens
    function deposit(uint256 assets, address receiver) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _checkForReporting(receiver, assets, "Deposit");
        return shares;
    }

    // Function to withdraw assets and burn vault tokens
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override whenNotPaused nonReentrant returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);
        _checkForReporting(owner, assets, "Withdrawal");
        return shares;
    }

    // Internal function to check for reporting based on threshold
    function _checkForReporting(address account, uint256 amount, string memory reportType) internal {
        if (amount >= reportingThreshold) {
            _submitReport(account, amount, reportType);
        }
    }

    // Internal function to submit a report to the regulatory authority
    function _submitReport(address account, uint256 amount, string memory reportType) internal {
        // Logic for submitting the report to the authority address
        // This can include calling an off-chain API or sending a message to an external system
        // For now, we'll just emit an event
        emit ReportSubmitted(account, amount, reportType, block.timestamp);
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
