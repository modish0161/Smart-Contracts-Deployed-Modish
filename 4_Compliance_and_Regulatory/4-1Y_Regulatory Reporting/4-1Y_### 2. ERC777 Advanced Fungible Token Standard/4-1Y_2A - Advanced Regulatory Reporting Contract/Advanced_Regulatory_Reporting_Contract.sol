// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AdvancedRegulatoryReporting is ERC777, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REPORTING_ROLE = keccak256("REPORTING_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    struct TransferDetails {
        address from;
        address to;
        uint256 amount;
        string purpose;
        uint256 timestamp;
    }

    mapping(address => TransferDetails[]) private _transferHistory;
    address[] private _reportedAddresses;

    event RegulatoryReportGenerated(address indexed reporter, uint256 timestamp, uint256 totalTransfers);
    event TransferPurposeSet(address indexed from, address indexed to, uint256 amount, string purpose);
    event ComplianceStatusUpdated(address indexed user, bool isCompliant);
    event TransactionRestricted(address indexed user, string reason);

    modifier onlyCompliant(address user) {
        require(isCompliant(user), "User is not compliant for token transfer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REPORTING_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    /**
     * @notice Records transfer details with a purpose.
     * @param from The address initiating the transfer.
     * @param to The address receiving the transfer.
     * @param amount The amount of tokens transferred.
     * @param purpose The purpose of the transfer.
     */
    function recordTransfer(
        address from,
        address to,
        uint256 amount,
        string memory purpose
    ) internal {
        TransferDetails memory details = TransferDetails({
            from: from,
            to: to,
            amount: amount,
            purpose: purpose,
            timestamp: block.timestamp
        });
        _transferHistory[from].push(details);
        _transferHistory[to].push(details);

        if (!_isReported(from)) {
            _reportedAddresses.push(from);
        }

        if (!_isReported(to)) {
            _reportedAddresses.push(to);
        }

        emit TransferPurposeSet(from, to, amount, purpose);
    }

    /**
     * @notice Sets compliance status for a user.
     * @param user The address of the user.
     * @param isCompliant The compliance status of the user.
     */
    function setComplianceStatus(address user, bool isCompliant) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        if (isCompliant) {
            _reportedAddresses.push(user);
        }
        emit ComplianceStatusUpdated(user, isCompliant);
    }

    /**
     * @notice Checks if an address is compliant.
     * @param user The address to check.
     * @return True if the user is compliant, false otherwise.
     */
    function isCompliant(address user) public view returns (bool) {
        return _reportedAddresses.length > 0;
    }

    /**
     * @notice Generates a regulatory report for all recorded transactions.
     * @return The list of all recorded addresses.
     */
    function generateRegulatoryReport() external onlyRole(REPORTING_ROLE) nonReentrant returns (address[] memory) {
        emit RegulatoryReportGenerated(msg.sender, block.timestamp, _reportedAddresses.length);
        return _reportedAddresses;
    }

    /**
     * @notice Checks if a user is already reported.
     * @param user The address to check.
     * @return True if the user is already reported, false otherwise.
     */
    function _isReported(address user) internal view returns (bool) {
        for (uint256 i = 0; i < _reportedAddresses.length; i++) {
            if (_reportedAddresses[i] == user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Override the ERC777 send function to include compliance checks and record transfers.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens sent.
     * @param data Additional data included in the transfer.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override onlyCompliant(_msgSender()) onlyCompliant(recipient) {
        super.send(recipient, amount, data);
        string memory purpose = string(data);
        recordTransfer(_msgSender(), recipient, amount, purpose);
    }

    /**
     * @notice Override the ERC777 operatorSend function to include compliance checks and record transfers.
     * @param sender The address of the sender.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens sent.
     * @param data Additional data included in the transfer.
     * @param operatorData Additional data from the operator.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public override onlyCompliant(sender) onlyCompliant(recipient) {
        super.operatorSend(sender, recipient, amount, data, operatorData);
        string memory purpose = string(data);
        recordTransfer(sender, recipient, amount, purpose);
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
     * @notice Grants compliance officer role to a new address.
     * @param account The address to grant the role to.
     */
    function grantComplianceOfficerRole(address account) external onlyOwner {
        grantRole(COMPLIANCE_OFFICER_ROLE, account);
    }

    /**
     * @notice Revokes compliance officer role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeComplianceOfficerRole(address account) external onlyOwner {
        revokeRole(COMPLIANCE_OFFICER_ROLE, account);
    }

    /**
     * @notice Grants reporting role to a new address.
     * @param account The address to grant the role to.
     */
    function grantReportingRole(address account) external onlyOwner {
        grantRole(REPORTING_ROLE, account);
    }

    /**
     * @notice Revokes reporting role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeReportingRole(address account) external onlyOwner {
        revokeRole(REPORTING_ROLE, account);
    }

    /**
     * @notice Allows the contract to receive ETH.
     */
    receive() external payable {}

    /**
     * @notice Withdraws all ETH from the contract.
     */
    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }
}
