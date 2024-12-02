// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC1404.sol"; // Interface for ERC1404 standard

contract SuspiciousActivityReporting is IERC1404, ERC20Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Threshold for large transactions
    uint256 public largeTransactionThreshold;
    // Address for submitting suspicious activity reports
    address public authorityAddress;
    // Mapping to store the last transaction amount for each address
    mapping(address => uint256) public lastTransactionAmount;

    // Events
    event SuspiciousActivityReported(address indexed from, address indexed to, uint256 amount, string reason, uint256 timestamp);

    // Constructor to initialize the contract with parameters
    constructor(
        string memory name,
        string memory symbol,
        uint256 _largeTransactionThreshold,
        address _authorityAddress
    ) ERC20(name, symbol) {
        largeTransactionThreshold = _largeTransactionThreshold;
        authorityAddress = _authorityAddress;
    }

    // Function to set the large transaction threshold
    function setLargeTransactionThreshold(uint256 _threshold) external onlyOwner {
        largeTransactionThreshold = _threshold;
    }

    // Function to set the authority address
    function setAuthorityAddress(address _address) external onlyOwner {
        require(_address != address(0), "Invalid authority address");
        authorityAddress = _address;
    }

    // Function to transfer tokens with compliance checks
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(_checkTransferRestrictions(msg.sender, to, amount), "Transfer restricted");

        bool success = super.transfer(to, amount);
        if (success) {
            _checkForSuspiciousActivity(msg.sender, to, amount);
        }
        return success;
    }

    // Function to transfer tokens from an address with compliance checks
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(_checkTransferRestrictions(from, to, amount), "Transfer restricted");

        bool success = super.transferFrom(from, to, amount);
        if (success) {
            _checkForSuspiciousActivity(from, to, amount);
        }
        return success;
    }

    // Internal function to check for suspicious activity
    function _checkForSuspiciousActivity(address from, address to, uint256 amount) internal {
        if (amount >= largeTransactionThreshold) {
            _reportSuspiciousActivity(from, to, amount, "Large transaction");
        }

        // Check for unusual transaction patterns
        if (lastTransactionAmount[from] > 0 && amount > lastTransactionAmount[from].mul(2)) {
            _reportSuspiciousActivity(from, to, amount, "Unusual transaction pattern");
        }

        lastTransactionAmount[from] = amount;
    }

    // Internal function to report suspicious activity
    function _reportSuspiciousActivity(address from, address to, uint256 amount, string memory reason) internal {
        emit SuspiciousActivityReported(from, to, amount, reason, block.timestamp);
        _submitReportToAuthority(from, to, amount, reason);
    }

    // Function to submit a report to the authority
    function _submitReportToAuthority(address from, address to, uint256 amount, string memory reason) internal {
        // Logic for submitting the report to the authority address
        // This can include calling an off-chain API or sending a message to an external system
        // For now, we'll just log an event
    }

    // Function to check transfer restrictions
    function _checkTransferRestrictions(address from, address to, uint256 amount) internal view returns (bool) {
        // Add compliance logic here
        // Ensure that both sender and receiver are compliant participants
        // Return true if transfer is allowed, false otherwise
        return true; // Placeholder for actual logic
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
