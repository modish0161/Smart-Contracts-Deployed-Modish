// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BasicRegulatoryReporting is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REGULATORY_ROLE = keccak256("REGULATORY_ROLE");

    struct TransactionRecord {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

    TransactionRecord[] private transactions;

    event TransactionRecorded(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ReportGenerated(address indexed regulator, uint256 reportId, uint256 timestamp);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REGULATORY_ROLE, msg.sender);
    }

    /**
     * @notice Override the transfer function to record transactions for regulatory reporting.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        super._transfer(sender, recipient, amount);
        _recordTransaction(sender, recipient, amount);
    }

    /**
     * @notice Records each token transfer transaction.
     * @param from The address sending tokens.
     * @param to The address receiving tokens.
     * @param amount The number of tokens transferred.
     */
    function _recordTransaction(address from, address to, uint256 amount) internal {
        transactions.push(TransactionRecord({
            from: from,
            to: to,
            amount: amount,
            timestamp: block.timestamp
        }));
        emit TransactionRecorded(from, to, amount, block.timestamp);
    }

    /**
     * @notice Allows regulatory authorities to generate and view a report of all recorded transactions.
     * @return TransactionRecord[] Array of all recorded transactions.
     */
    function generateReport() external onlyRole(REGULATORY_ROLE) nonReentrant returns (TransactionRecord[] memory) {
        emit ReportGenerated(msg.sender, transactions.length, block.timestamp);
        return transactions;
    }

    /**
     * @notice Pauses all token transfers. Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Grants regulatory role to a new address.
     * @param account The address to grant the role to.
     */
    function grantRegulatoryRole(address account) external onlyOwner {
        grantRole(REGULATORY_ROLE, account);
    }

    /**
     * @notice Revokes regulatory role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeRegulatoryRole(address account) external onlyOwner {
        revokeRole(REGULATORY_ROLE, account);
    }
}
