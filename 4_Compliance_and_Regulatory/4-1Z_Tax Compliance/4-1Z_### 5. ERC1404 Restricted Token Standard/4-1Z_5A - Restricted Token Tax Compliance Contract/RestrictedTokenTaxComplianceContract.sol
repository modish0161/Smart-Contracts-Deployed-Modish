// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RestrictedTokenTaxComplianceContract is ERC1404, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax calculations and transactions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Address of the tax authority to receive withheld taxes
    address public taxAuthority;

    // Tax rates for different transaction types
    struct TaxRate {
        uint256 transferTaxRate; // In basis points (e.g., 500 = 5%)
        uint256 dividendTaxRate; // In basis points (e.g., 1500 = 15%)
    }

    // Mapping to store tax rates for each token type (partition)
    mapping(bytes32 => TaxRate) public taxRates;

    // Events for tracking tax operations
    event TaxWithheld(address indexed holder, uint256 amount, uint256 taxAmount, bytes32 partition);
    event TaxRateUpdated(bytes32 indexed partition, uint256 transferTaxRate, uint256 dividendTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address initialTaxAuthority
    ) ERC1404(name, symbol, controllers) {
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        taxAuthority = initialTaxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Modifier to check if caller is a compliance officer
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to set tax rates for a token partition (only compliance officer)
    function setTaxRates(
        bytes32 partition,
        uint256 transferTaxRate,
        uint256 dividendTaxRate
    ) external onlyComplianceOfficer {
        require(transferTaxRate <= 10000 && dividendTaxRate <= 10000, "Tax rates should be <= 100%");
        taxRates[partition] = TaxRate(transferTaxRate, dividendTaxRate);
        emit TaxRateUpdated(partition, transferTaxRate, dividendTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override transfer function to include tax withholding
    function _transferWithTax(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        uint256 taxAmount = (value * taxRates[partition].transferTaxRate) / 10000;
        uint256 netAmount = value - taxAmount;

        require(balanceOfByPartition(partition, from) >= value, "Insufficient balance");

        // Withhold tax and transfer to tax authority
        if (taxAmount > 0) {
            super._transferWithData(partition, from, taxAuthority, taxAmount, data);
            emit TaxWithheld(from, value, taxAmount, partition);
        }

        // Transfer net amount to recipient
        super._transferWithData(partition, from, to, netAmount, data);
    }

    // Override transfer function to ensure tax compliance
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        _transferWithTax(partition, msg.sender, to, value, data);
        return partition;
    }

    // Override redeem function to include tax withholding on dividends
    function redeemByPartition(
        bytes32 partition,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        uint256 taxAmount = (value * taxRates[partition].dividendTaxRate) / 10000;
        uint256 netAmount = value - taxAmount;

        require(balanceOfByPartition(partition, msg.sender) >= value, "Insufficient balance");

        // Withhold tax and transfer to tax authority
        if (taxAmount > 0) {
            super._transferWithData(partition, msg.sender, taxAuthority, taxAmount, data);
            emit TaxWithheld(msg.sender, value, taxAmount, partition);
        }

        // Redeem net amount
        return super.redeemByPartition(partition, netAmount, data);
    }

    // Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to add a compliance officer (only owner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (only owner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }

    // Function to get tax rates for a partition
    function getTaxRates(bytes32 partition) external view returns (uint256 transferTaxRate, uint256 dividendTaxRate) {
        TaxRate memory rate = taxRates[partition];
        return (rate.transferTaxRate, rate.dividendTaxRate);
    }
}
