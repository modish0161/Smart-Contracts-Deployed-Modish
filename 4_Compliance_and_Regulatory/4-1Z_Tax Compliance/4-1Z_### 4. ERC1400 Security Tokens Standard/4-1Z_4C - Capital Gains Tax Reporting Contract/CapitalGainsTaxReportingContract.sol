// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For price feeds

contract CapitalGainsTaxReportingContract is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax calculations and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store acquisition prices and timestamps for each holder and token partition
    struct TokenTransaction {
        uint256 acquisitionPrice; // In USD (scaled)
        uint256 acquisitionTimestamp;
    }

    mapping(address => mapping(bytes32 => TokenTransaction)) private _acquisitions; // holder => partition => TokenTransaction

    // Address of the Chainlink price feed for token valuation
    AggregatorV3Interface internal priceFeed;

    // Events for tracking tax operations
    event CapitalGainsTaxReported(address indexed holder, uint256 salePrice, uint256 acquisitionPrice, uint256 capitalGains, uint256 taxAmount, uint256 timestamp);
    event AcquisitionRecorded(address indexed holder, bytes32 partition, uint256 acquisitionPrice, uint256 timestamp);
    event TaxRateUpdated(uint256 newTaxRate, address updatedBy);

    // Tax rate in basis points (e.g., 1000 = 10%)
    uint256 public taxRate;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        address priceFeedAddress,
        uint256 initialTaxRate
    ) ERC1400(name, symbol, controllers) {
        require(priceFeedAddress != address(0), "Invalid price feed address");
        require(initialTaxRate <= 10000, "Tax rate should be <= 100%");

        priceFeed = AggregatorV3Interface(priceFeedAddress);
        taxRate = initialTaxRate;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Function to set a new capital gains tax rate (only compliance officer)
    function setTaxRate(uint256 newTaxRate) external onlyRole(COMPLIANCE_ROLE) {
        require(newTaxRate <= 10000, "Tax rate should be <= 100%");
        taxRate = newTaxRate;
        emit TaxRateUpdated(newTaxRate, msg.sender);
    }

    // Function to get the latest price from the Chainlink price feed
    function getLatestPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        return price;
    }

    // Function to record acquisition price and timestamp for a partition
    function recordAcquisition(
        bytes32 partition,
        address holder,
        uint256 acquisitionPrice
    ) external onlyRole(COMPLIANCE_ROLE) {
        require(holder != address(0), "Invalid holder address");
        _acquisitions[holder][partition] = TokenTransaction(acquisitionPrice, block.timestamp);
        emit AcquisitionRecorded(holder, partition, acquisitionPrice, block.timestamp);
    }

    // Function to calculate and report capital gains tax on a token sale
    function reportCapitalGainsTax(
        bytes32 partition,
        address holder,
        uint256 salePrice
    ) external nonReentrant whenNotPaused onlyRole(COMPLIANCE_ROLE) {
        require(holder != address(0), "Invalid holder address");
        require(_acquisitions[holder][partition].acquisitionPrice > 0, "Acquisition not recorded");

        uint256 acquisitionPrice = _acquisitions[holder][partition].acquisitionPrice;
        uint256 capitalGains = salePrice > acquisitionPrice ? salePrice - acquisitionPrice : 0;
        uint256 taxAmount = (capitalGains * taxRate) / 10000;

        emit CapitalGainsTaxReported(holder, salePrice, acquisitionPrice, capitalGains, taxAmount, block.timestamp);

        // Transfer the tax amount to the tax authority (can be defined as the owner or another contract)
        _transferByPartition(partition, holder, owner(), taxAmount, "");
    }

    // Internal function to handle token transfers
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

    // Function to get acquisition details for a holder
    function getAcquisitionDetails(address holder, bytes32 partition) external view returns (uint256 acquisitionPrice, uint256 acquisitionTimestamp) {
        TokenTransaction memory acquisition = _acquisitions[holder][partition];
        return (acquisition.acquisitionPrice, acquisition.acquisitionTimestamp);
    }
}
