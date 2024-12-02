// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DividendWithholdingTaxContract is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax rates and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store withholding tax rates for different jurisdictions
    mapping(bytes32 => uint256) private _dividendTaxRates; // jurisdiction => taxRate (in basis points, e.g., 500 = 5%)

    // Address where collected taxes will be sent
    address public taxAuthority;

    // Events for tracking tax operations
    event DividendPaid(bytes32 indexed partition, address indexed holder, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxWithheld(bytes32 indexed partition, address indexed holder, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxRateUpdated(bytes32 indexed jurisdiction, uint256 newTaxRate, address updatedBy);
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

    // Function to set a new dividend tax rate for a specific jurisdiction (only compliance officer)
    function setDividendTaxRate(bytes32 jurisdiction, uint256 taxRate) external onlyRole(COMPLIANCE_ROLE) {
        require(taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        _dividendTaxRates[jurisdiction] = taxRate;
        emit TaxRateUpdated(jurisdiction, taxRate, msg.sender);
    }

    // Function to get the dividend tax rate of a specific jurisdiction
    function getDividendTaxRate(bytes32 jurisdiction) external view returns (uint256) {
        return _dividendTaxRates[jurisdiction];
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
        emit TaxAuthorityUpdated(_taxAuthority, msg.sender);
    }

    // Function to distribute dividends with tax withholding
    function distributeDividendsWithTax(
        bytes32 partition,
        address[] calldata holders,
        uint256[] calldata amounts,
        bytes32[] calldata jurisdictions
    ) external nonReentrant whenNotPaused onlyRole(COMPLIANCE_ROLE) {
        require(holders.length == amounts.length && amounts.length == jurisdictions.length, "Array lengths must match");

        for (uint256 i = 0; i < holders.length; i++) {
            uint256 taxRate = _dividendTaxRates[jurisdictions[i]];
            uint256 taxAmount = (amounts[i] * taxRate) / 10000;
            uint256 amountAfterTax = amounts[i] - taxAmount;

            _transferByPartition(partition, msg.sender, holders[i], amountAfterTax, "");
            _transferByPartition(partition, msg.sender, taxAuthority, taxAmount, "");

            emit DividendPaid(partition, holders[i], amounts[i], taxAmount, block.timestamp);
            emit TaxWithheld(partition, holders[i], amounts[i], taxAmount, block.timestamp);
        }
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

    // Function to get dividend tax details of a jurisdiction
    function getDividendTaxDetails(bytes32 jurisdiction, uint256 amount) external view returns (uint256 taxRate, uint256 taxAmount) {
        taxRate = _dividendTaxRates[jurisdiction];
        taxAmount = (amount * taxRate) / 10000;
    }

    // Internal function to handle transfer with dividend tax calculation
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
