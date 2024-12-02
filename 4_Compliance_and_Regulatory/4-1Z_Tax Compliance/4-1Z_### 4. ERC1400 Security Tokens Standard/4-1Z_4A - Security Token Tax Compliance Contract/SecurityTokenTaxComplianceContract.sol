// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SecurityTokenTaxComplianceContract is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax rates and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store tax rates for different security token partitions
    mapping(bytes32 => uint256) private _taxRates; // partition => taxRate (in basis points, e.g., 500 = 5%)

    // Address where collected taxes will be sent
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxWithheld(bytes32 indexed partition, address indexed from, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxReported(address indexed from, bytes32 indexed partition, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxRateUpdated(bytes32 indexed partition, uint256 newTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address newTaxAuthority, address updatedBy);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address _taxAuthority
    ) ERC1400(name, symbol, controllers) {
        require(_taxAuthority != address(0), "Invalid tax authority address");

        taxAuthority = _taxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Function to set a new tax rate for a specific partition (only compliance officer)
    function setTaxRate(bytes32 partition, uint256 taxRate) external onlyRole(COMPLIANCE_ROLE) {
        require(taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        _taxRates[partition] = taxRate;
        emit TaxRateUpdated(partition, taxRate, msg.sender);
    }

    // Function to get the tax rate of a specific partition
    function getTaxRate(bytes32 partition) external view returns (uint256) {
        return _taxRates[partition];
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
        emit TaxAuthorityUpdated(_taxAuthority, msg.sender);
    }

    // Function to transfer tokens with tax calculation and withholding
    function transferWithTax(
        bytes32 partition,
        address to,
        uint256 value,
        bytes calldata data
    ) external nonReentrant whenNotPaused {
        uint256 taxRate = _taxRates[partition];
        uint256 taxAmount = (value * taxRate) / 10000;
        uint256 amountAfterTax = value - taxAmount;

        _transferByPartition(partition, msg.sender, to, amountAfterTax, data);
        _transferByPartition(partition, msg.sender, taxAuthority, taxAmount, data);

        emit TaxWithheld(partition, msg.sender, value, taxAmount, block.timestamp);
    }

    // Function to report taxes manually by a compliance officer
    function reportTax(
        bytes32 partition,
        uint256 value,
        uint256 taxAmount
    ) external nonReentrant onlyRole(COMPLIANCE_ROLE) whenNotPaused {
        _transferByPartition(partition, msg.sender, taxAuthority, taxAmount, "");
        emit TaxReported(msg.sender, partition, value, taxAmount, block.timestamp);
    }

    // Function to add a compliance officer (only owner)
    function addComplianceOfficer(address officer) external onlyOwner {
        grantRole(COMPLIANCE_ROLE, officer);
    }

    // Function to remove a compliance officer (only owner)
    function removeComplianceOfficer(address officer) external onlyOwner {
        revokeRole(COMPLIANCE_ROLE, officer);
    }

    // Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get tax details of a partition
    function getTaxDetails(bytes32 partition, uint256 value) external view returns (uint256 taxRate, uint256 taxAmount) {
        taxRate = _taxRates[partition];
        taxAmount = (value * taxRate) / 10000;
    }

    // Internal function to handle transfer with tax calculation
    function _transferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        require(to != address(0), "ERC1400: transfer to the zero address");
        _transferWithData(partition, from, to, value, data);
    }
}
