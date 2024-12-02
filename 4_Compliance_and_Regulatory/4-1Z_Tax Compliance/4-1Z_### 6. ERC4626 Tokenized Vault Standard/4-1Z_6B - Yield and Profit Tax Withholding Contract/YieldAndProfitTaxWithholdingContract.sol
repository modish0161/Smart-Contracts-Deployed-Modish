// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract YieldAndProfitTaxWithholdingContract is ERC4626, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers to manage tax settings and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Tax rates for yield and profit (in basis points, where 10000 = 100%)
    uint256 public yieldTaxRate;
    uint256 public profitTaxRate;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxRateUpdated(uint256 yieldTaxRate, uint256 profitTaxRate, address updatedBy);
    event TaxWithheld(address indexed investor, uint256 yieldTax, uint256 profitTax, address indexed taxAuthority);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        uint256 _yieldTaxRate,
        uint256 _profitTaxRate,
        address initialTaxAuthority
    ) ERC4626(asset, name, symbol) {
        require(_yieldTaxRate <= 10000 && _profitTaxRate <= 10000, "Invalid tax rates");
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        yieldTaxRate = _yieldTaxRate;
        profitTaxRate = _profitTaxRate;
        taxAuthority = initialTaxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Modifier to restrict function access to compliance officers
    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not a compliance officer");
        _;
    }

    // Function to set tax rates (only by compliance officers)
    function setTaxRates(uint256 _yieldTaxRate, uint256 _profitTaxRate) external onlyComplianceOfficer {
        require(_yieldTaxRate <= 10000 && _profitTaxRate <= 10000, "Invalid tax rates");
        yieldTaxRate = _yieldTaxRate;
        profitTaxRate = _profitTaxRate;
        emit TaxRateUpdated(yieldTaxRate, profitTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override deposit function to withhold tax on profit
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        // Calculate and withhold profit tax
        uint256 profit = _calculateProfit(assets);
        uint256 profitTax = (profit * profitTaxRate) / 10000;
        _withholdTax(receiver, profitTax, 0);

        return shares;
    }

    // Override withdraw function to withhold tax on yield
    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);

        // Calculate and withhold yield tax
        uint256 yield = _calculateYield(assets);
        uint256 yieldTax = (yield * yieldTaxRate) / 10000;
        _withholdTax(owner, 0, yieldTax);

        return shares;
    }

    // Internal function to calculate profit (can be customized)
    function _calculateProfit(uint256 assets) internal view returns (uint256) {
        // Placeholder logic for profit calculation
        return (assets * 10) / 100; // Example: 10% profit assumed
    }

    // Internal function to calculate yield (can be customized)
    function _calculateYield(uint256 assets) internal view returns (uint256) {
        // Placeholder logic for yield calculation
        return (assets * 5) / 100; // Example: 5% yield assumed
    }

    // Internal function to withhold tax
    function _withholdTax(address investor, uint256 profitTax, uint256 yieldTax) internal {
        uint256 totalTax = profitTax + yieldTax;

        if (totalTax > 0) {
            IERC20(asset()).transferFrom(investor, taxAuthority, totalTax);
            emit TaxWithheld(investor, yieldTax, profitTax, taxAuthority);
        }
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

    // Function to get the current tax rates
    function getTaxRates() external view returns (uint256, uint256) {
        return (yieldTaxRate, profitTaxRate);
    }
}
