// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OperatorControlledReporting is ERC777, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    struct TransferData {
        address from;
        address to;
        uint256 amount;
        string purpose;
        uint256 timestamp;
    }

    TransferData[] private _transferRecords;
    mapping(address => bool) private _reportedAddresses;

    event ReportSubmitted(address indexed operator, uint256 timestamp, uint256 totalTransfers);
    event TransferRecorded(address indexed from, address indexed to, uint256 amount, string purpose);
    event ReportAuthorized(address indexed complianceOfficer, uint256 timestamp);
    event OperatorStatusChanged(address indexed operator, bool status);

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Caller is not an operator");
        _;
    }

    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_OFFICER_ROLE, _msgSender()), "Caller is not a compliance officer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    /**
     * @notice Records the details of a token transfer.
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
        TransferData memory transferData = TransferData({
            from: from,
            to: to,
            amount: amount,
            purpose: purpose,
            timestamp: block.timestamp
        });
        _transferRecords.push(transferData);
        _reportedAddresses[from] = true;
        _reportedAddresses[to] = true;

        emit TransferRecorded(from, to, amount, purpose);
    }

    /**
     * @notice Allows an operator to submit a report of all transfers.
     */
    function submitReport() external onlyOperator nonReentrant {
        require(_transferRecords.length > 0, "No transfer data to report");
        emit ReportSubmitted(_msgSender(), block.timestamp, _transferRecords.length);
    }

    /**
     * @notice Allows a compliance officer to authorize a report.
     */
    function authorizeReport() external onlyComplianceOfficer {
        emit ReportAuthorized(_msgSender(), block.timestamp);
    }

    /**
     * @notice Grants operator role to a new address.
     * @param account The address to grant the role to.
     */
    function grantOperatorRole(address account) external onlyOwner {
        grantRole(OPERATOR_ROLE, account);
        emit OperatorStatusChanged(account, true);
    }

    /**
     * @notice Revokes operator role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeOperatorRole(address account) external onlyOwner {
        revokeRole(OPERATOR_ROLE, account);
        emit OperatorStatusChanged(account, false);
    }

    /**
     * @notice Override the ERC777 send function to include transfer recording.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens sent.
     * @param data Additional data included in the transfer.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public override onlyOperator {
        super.send(recipient, amount, data);
        string memory purpose = string(data);
        recordTransfer(_msgSender(), recipient, amount, purpose);
    }

    /**
     * @notice Override the ERC777 operatorSend function to include transfer recording.
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
    ) public override onlyOperator {
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
