// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract OperatorControlledTaxReportingContract is ERC777, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for designated operators (e.g., compliance officers)
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Struct to store detailed transaction data for tax purposes
    struct TransactionData {
        address from;
        address to;
        uint256 amount;
        uint256 taxAmount;
        string taxType;
        bool authorized;
        uint256 timestamp;
    }

    // Mapping to store transaction data for compliance review and tax reporting
    mapping(uint256 => TransactionData) public transactions;
    uint256 public transactionCounter;

    // Tax rate in basis points (e.g., 500 = 5%)
    uint256 public taxRate;
    // Address where collected taxes will be sent
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxWithheld(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, string taxType, uint256 transactionId);
    event TaxAuthorized(uint256 transactionId, bool authorized, address authorizedBy);
    event TaxReported(uint256 totalTaxCollected, uint256 timestamp);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        uint256 _initialSupply,
        uint256 _taxRate,
        address _taxAuthority
    ) ERC777(name, symbol, defaultOperators) {
        require(_taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        require(_taxAuthority != address(0), "Invalid tax authority address");

        _mint(msg.sender, _initialSupply, "", "");
        taxRate = _taxRate;
        taxAuthority = _taxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    // Function to set a new tax rate (only owner)
    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        taxRate = _taxRate;
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
    }

    // Function for an operator to authorize a transaction for tax reporting
    function authorizeTransaction(uint256 transactionId, bool authorized) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
        require(transactionId < transactionCounter, "Invalid transaction ID");
        transactions[transactionId].authorized = authorized;
        emit TaxAuthorized(transactionId, authorized, msg.sender);
    }

    // Function to report collected taxes to the authority
    function reportTax() external nonReentrant whenNotPaused {
        uint256 totalTaxCollected = 0;

        for (uint256 i = 0; i < transactionCounter; i++) {
            if (transactions[i].authorized) {
                totalTaxCollected += transactions[i].taxAmount;
                delete transactions[i];
            }
        }

        _send(address(this), taxAuthority, totalTaxCollected, "", "", false);
        emit TaxReported(totalTaxCollected, block.timestamp);
    }

    // Overridden send function to include tax calculation and withholding
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal override whenNotPaused {
        uint256 taxAmount = (amount * taxRate) / 10000;
        uint256 amountAfterTax = amount - taxAmount;

        super._send(from, to, amountAfterTax, data, operatorData, requireReceptionAck);
        if (taxAmount > 0) {
            super._send(from, address(this), taxAmount, data, operatorData, requireReceptionAck);

            // Store transaction data for review
            transactions[transactionCounter] = TransactionData({
                from: from,
                to: to,
                amount: amount,
                taxAmount: taxAmount,
                taxType: "General Tax", // Customize this for specific tax types
                authorized: false,
                timestamp: block.timestamp
            });

            emit TaxWithheld(from, to, amount, taxAmount, "General Tax", transactionCounter);
            transactionCounter++;
        }
    }

    // Function to add an operator (only owner)
    function addOperator(address operator) external onlyOwner {
        grantRole(OPERATOR_ROLE, operator);
    }

    // Function to remove an operator (only owner)
    function removeOperator(address operator) external onlyOwner {
        revokeRole(OPERATOR_ROLE, operator);
    }

    // Function to pause all token transfers (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause all token transfers (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }
}
