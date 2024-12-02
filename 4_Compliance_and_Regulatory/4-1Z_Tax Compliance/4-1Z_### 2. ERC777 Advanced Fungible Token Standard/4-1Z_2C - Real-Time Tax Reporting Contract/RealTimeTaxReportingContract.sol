// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RealTimeTaxReportingContract is ERC777, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for designated operators (e.g., compliance officers)
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Tax rate in basis points (e.g., 500 = 5%)
    uint256 public taxRate;
    // Address where collected taxes will be sent in real-time
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxWithheld(address indexed from, address indexed to, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxRateUpdated(uint256 newTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address newTaxAuthority, address updatedBy);

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
        emit TaxRateUpdated(_taxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
        emit TaxAuthorityUpdated(_taxAuthority, msg.sender);
    }

    // Overridden send function to include tax calculation and real-time reporting
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
            super._send(from, taxAuthority, taxAmount, data, operatorData, requireReceptionAck);

            emit TaxWithheld(from, to, amount, taxAmount, block.timestamp);
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
