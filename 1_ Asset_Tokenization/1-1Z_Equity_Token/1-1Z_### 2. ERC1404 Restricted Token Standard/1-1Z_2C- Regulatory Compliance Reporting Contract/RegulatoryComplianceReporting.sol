// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Regulatory Compliance Reporting Contract
/// @notice This contract automates the generation and submission of reports to regulators, ensuring compliance with equity token transactions based on ERC1404.
contract RegulatoryComplianceReporting is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Struct to store transaction information for reporting purposes
    struct TokenTransaction {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        bool isCompliant;
    }

    // Array to hold all token transactions for reporting
    TokenTransaction[] private transactionHistory;

    // Mapping to store compliance status for individual addresses
    mapping(address => bool) private compliantEntities;

    // Events for reporting and compliance updates
    event ComplianceStatusUpdated(address indexed account, bool status);
    event RegulatoryReportGenerated(uint256 indexed reportId, uint256 timestamp, address indexed generatedBy);

    /// @notice Constructor to initialize the ERC20 token with details
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    /// @param initialSupply Initial supply of tokens to be minted to the deployer
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /// @notice Set the compliance status of an address
    /// @param account Address to update the compliance status for
    /// @param status True to mark as compliant, false to mark as non-compliant
    function setComplianceStatus(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        compliantEntities[account] = status;
        emit ComplianceStatusUpdated(account, status);
    }

    /// @notice Transfer function overridden to check compliance before allowing transfers
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(compliantEntities[msg.sender], "Sender is not compliant");
        require(compliantEntities[recipient], "Recipient is not compliant");

        // Record transaction for compliance reporting
        transactionHistory.push(
            TokenTransaction({
                from: msg.sender,
                to: recipient,
                amount: amount,
                timestamp: block.timestamp,
                isCompliant: true
            })
        );

        return super.transfer(recipient, amount);
    }

    /// @notice TransferFrom function overridden to check compliance before allowing transfers
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(compliantEntities[sender], "Sender is not compliant");
        require(compliantEntities[recipient], "Recipient is not compliant");

        // Record transaction for compliance reporting
        transactionHistory.push(
            TokenTransaction({
                from: sender,
                to: recipient,
                amount: amount,
                timestamp: block.timestamp,
                isCompliant: true
            })
        );

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Generate a regulatory compliance report for transactions that have occurred
    /// @param regulator Address of the regulator to send the report to
    function generateComplianceReport(address regulator) external onlyRole(COMPLIANCE_ROLE) nonReentrant whenNotPaused {
        require(regulator != address(0), "Invalid regulator address");

        // For simplicity, we just emit an event here to simulate the sending of a report
        emit RegulatoryReportGenerated(transactionHistory.length, block.timestamp, msg.sender);

        // In a real-world scenario, this is where off-chain logic would send reports via a trusted third-party.
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Get all recorded transactions for reporting
    /// @return Array of recorded transactions
    function getTransactionHistory() external view returns (TokenTransaction[] memory) {
        return transactionHistory;
    }

    /// @notice Mint new tokens (only by admin)
    /// @param account Address to mint the tokens to
    /// @param amount Amount of tokens to mint
    function mint(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(account, amount);
    }

    /// @notice Burn tokens (only by admin)
    /// @param account Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }
}
