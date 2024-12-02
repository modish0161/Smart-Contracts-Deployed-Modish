// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTaxComplianceContract is ERC4626, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers who can manage tax rates and reporting
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Tax rates (in basis points, where 10000 = 100%)
    uint256 public profitTaxRate;
    uint256 public yieldTaxRate;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxRateUpdated(uint256 profitTaxRate, uint256 yieldTaxRate, address updatedBy);
    event TaxWithheld(address indexed investor, uint256 profit, uint256 yield, uint256 profitTaxWithheld, uint256 yieldTaxWithheld);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        uint256 _profitTaxRate,
        uint256 _yieldTaxRate,
        address initialTaxAuthority
    ) ERC4626(asset, name, symbol) {
        require(_profitTaxRate <= 10000 && _yieldTaxRate <= 10000, "Invalid tax rates");
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        profitTaxRate = _profitTaxRate;
        yieldTaxRate = _yieldTaxRate;
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

    // Function to set tax rates (only by compliance officer)
    function setTaxRates(uint256 _profitTaxRate, uint256 _yieldTaxRate) external onlyComplianceOfficer {
        require(_profitTaxRate <= 10000 && _yieldTaxRate <= 10000, "Invalid tax rates");
        profitTaxRate = _profitTaxRate;
        yieldTaxRate = _yieldTaxRate;
        emit TaxRateUpdated(profitTaxRate, yieldTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override deposit function to include tax withholding on profits
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        // Calculate and withhold taxes on profit (if applicable)
        uint256 profit = _calculateProfit(assets);
        uint256 profitTax = (profit * profitTaxRate) / 10000;
        _withholdTax(receiver, profitTax, 0);

        return shares;
    }

    // Override withdraw function to include tax withholding on yield
    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);

        // Calculate and withhold taxes on yield (if applicable)
        uint256 yield = _calculateYield(assets);
        uint256 yieldTax = (yield * yieldTaxRate) / 10000;
        _withholdTax(owner, 0, yieldTax);

        return shares;
    }

    // Function to withhold tax on profit and yield
    function _withholdTax(address investor, uint256 profitTax, uint256 yieldTax) internal {
        uint256 totalTax = profitTax + yieldTax;

        if (totalTax > 0) {
            // Transfer withheld tax to tax authority
            IERC20(asset()).transferFrom(investor, taxAuthority, totalTax);

            // Emit event for tax withholding
            emit TaxWithheld(investor, profitTax, yieldTax, profitTax, yieldTax);
        }
    }

    // Function to calculate profit for tax purposes (customize as needed)
    function _calculateProfit(uint256 assets) internal view returns (uint256) {
        // Placeholder logic: customize profit calculation based on vault's logic
        return (assets * 10) / 100; // Example: 10% profit assumed
    }

    // Function to calculate yield for tax purposes (customize as needed)
    function _calculateYield(uint256 assets) internal view returns (uint256) {
        // Placeholder logic: customize yield calculation based on vault's logic
        return (assets * 5) / 100; // Example: 5% yield assumed
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
        return (profitTaxRate, yieldTaxRate);
    }
}
