// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TransactionBasedTaxReportingContract is ERC20, Ownable, ReentrancyGuard, Pausable {
    // Tax rate in basis points (e.g., 500 = 5%)
    uint256 public taxRate;
    // Address where collected taxes will be sent
    address public taxAuthority;
    // Reporting interval in seconds (e.g., 86400 = 1 day)
    uint256 public reportingInterval;
    // Timestamp of the last tax report
    uint256 public lastReportTimestamp;
    // Total tax collected since the last report
    uint256 public totalTaxCollected;

    // Event for tax withholding and reporting
    event TaxWithheld(address indexed from, address indexed to, uint256 amount, uint256 taxAmount);
    event TaxReported(uint256 totalTaxCollected, uint256 timestamp);
    event TaxRateUpdated(uint256 oldRate, uint256 newRate);
    event TaxAuthorityUpdated(address oldAuthority, address newAuthority);
    event ReportingIntervalUpdated(uint256 oldInterval, uint256 newInterval);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialSupply,
        uint256 _taxRate,
        address _taxAuthority,
        uint256 _reportingInterval
    ) ERC20(name, symbol) {
        require(_taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        require(_taxAuthority != address(0), "Invalid tax authority address");
        require(_reportingInterval > 0, "Reporting interval should be greater than zero");

        _mint(msg.sender, _initialSupply * 10 ** decimals());
        taxRate = _taxRate;
        taxAuthority = _taxAuthority;
        reportingInterval = _reportingInterval;
        lastReportTimestamp = block.timestamp;
    }

    // Function to set a new tax rate (only owner)
    function setTaxRate(uint256 _taxRate) external onlyOwner {
        require(_taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        emit TaxRateUpdated(taxRate, _taxRate);
        taxRate = _taxRate;
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        emit TaxAuthorityUpdated(taxAuthority, _taxAuthority);
        taxAuthority = _taxAuthority;
    }

    // Function to set a new reporting interval (only owner)
    function setReportingInterval(uint256 _reportingInterval) external onlyOwner {
        require(_reportingInterval > 0, "Reporting interval should be greater than zero");
        emit ReportingIntervalUpdated(reportingInterval, _reportingInterval);
        reportingInterval = _reportingInterval;
    }

    // Function to report and reset total tax collected to the authority
    function reportTax() external nonReentrant whenNotPaused {
        require(block.timestamp >= lastReportTimestamp + reportingInterval, "Reporting interval not yet passed");
        require(totalTaxCollected > 0, "No tax to report");

        _transfer(address(this), taxAuthority, totalTaxCollected);
        emit TaxReported(totalTaxCollected, block.timestamp);
        totalTaxCollected = 0;
        lastReportTimestamp = block.timestamp;
    }

    // Overridden transfer function to include tax calculation and withholding
    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");

        uint256 taxAmount = (amount * taxRate) / 10000;
        uint256 amountAfterTax = amount - taxAmount;

        super._transfer(from, to, amountAfterTax);
        if (taxAmount > 0) {
            super._transfer(from, address(this), taxAmount);
            totalTaxCollected += taxAmount;
            emit TaxWithheld(from, to, amount, taxAmount);
        }

        if (block.timestamp >= lastReportTimestamp + reportingInterval) {
            reportTax();
        }
    }

    // Function to pause all transfers (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause all transfers (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }
}
