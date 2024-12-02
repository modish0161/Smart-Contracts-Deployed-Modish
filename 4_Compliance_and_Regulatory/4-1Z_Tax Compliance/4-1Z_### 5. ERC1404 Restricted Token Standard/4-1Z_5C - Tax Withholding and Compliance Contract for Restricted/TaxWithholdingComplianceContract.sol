// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TaxWithholdingComplianceContract is ERC1404, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax rates, withholding, and reporting
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store tax rates for each partition (restricted token category)
    mapping(bytes32 => uint256) public partitionTaxRates;

    // Mapping to store tax data for each investor and partition
    struct TaxData {
        uint256 totalTaxableAmount;
        uint256 totalTaxWithheld;
    }
    mapping(address => mapping(bytes32 => TaxData)) public investorTaxData;

    // Address of the tax authority for withheld tax remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxWithheld(address indexed investor, bytes32 partition, uint256 taxableAmount, uint256 taxWithheld);
    event TaxRateUpdated(bytes32 indexed partition, uint256 taxRate, address updatedBy);
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

    // Function to set tax rate for a specific partition (restricted token)
    function setPartitionTaxRate(bytes32 partition, uint256 taxRate) external onlyComplianceOfficer {
        require(taxRate <= 10000, "Tax rate must be in basis points (<= 100%)");
        partitionTaxRates[partition] = taxRate;
        emit TaxRateUpdated(partition, taxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Function to withhold tax on a restricted token transfer
    function withholdTax(address investor, bytes32 partition, uint256 amount) internal {
        uint256 taxRate = partitionTaxRates[partition];
        uint256 taxAmount = (amount * taxRate) / 10000;

        // Update investor tax data
        investorTaxData[investor][partition].totalTaxableAmount += amount;
        investorTaxData[investor][partition].totalTaxWithheld += taxAmount;

        // Emit event for tax withholding
        emit TaxWithheld(investor, partition, amount, taxAmount);

        // Transfer tax amount to the tax authority
        _transfer(investor, taxAuthority, taxAmount);
    }

    // Override transferByPartition to include tax withholding logic
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        require(_canTransfer(msg.sender, to, value, partition), "Transfer restricted");

        // Withhold tax before transfer
        withholdTax(msg.sender, partition, value);

        // Proceed with the transfer
        return super.transferByPartition(partition, to, value, data);
    }

    // Override redeemByPartition to include tax withholding logic
    function redeemByPartition(
        bytes32 partition,
        uint256 value,
        bytes memory data
    ) public override nonReentrant whenNotPaused returns (bytes32) {
        require(_canTransfer(msg.sender, address(0), value, partition), "Redemption restricted");

        // Withhold tax before redemption
        withholdTax(msg.sender, partition, value);

        // Proceed with the redemption
        return super.redeemByPartition(partition, value, data);
    }

    // Internal function to check transfer restrictions
    function _canTransfer(address from, address to, uint256 value, bytes32 partition) internal view returns (bool) {
        // Implement custom logic for checking transfer restrictions based on tax compliance
        return true; // Placeholder for actual logic
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

    // Function to get tax data for a specific investor and partition
    function getInvestorTaxData(address investor, bytes32 partition)
        external
        view
        returns (uint256 totalTaxableAmount, uint256 totalTaxWithheld)
    {
        TaxData memory taxData = investorTaxData[investor][partition];
        return (taxData.totalTaxableAmount, taxData.totalTaxWithheld);
    }
}
