// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WithdrawalTaxReportingContract is ERC4626, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for compliance officers to manage tax settings and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Tax rates for withdrawals (in basis points, where 10000 = 100%)
    uint256 public withdrawalTaxRate;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxRateUpdated(uint256 withdrawalTaxRate, address updatedBy);
    event TaxWithheld(address indexed investor, uint256 withdrawalTax, address indexed taxAuthority);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        uint256 _withdrawalTaxRate,
        address initialTaxAuthority
    ) ERC4626(asset, name, symbol) {
        require(_withdrawalTaxRate <= 10000, "Invalid tax rate");
        require(initialTaxAuthority != address(0), "Invalid tax authority address");

        withdrawalTaxRate = _withdrawalTaxRate;
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

    // Function to set the withdrawal tax rate (only by compliance officers)
    function setWithdrawalTaxRate(uint256 _withdrawalTaxRate) external onlyComplianceOfficer {
        require(_withdrawalTaxRate <= 10000, "Invalid tax rate");
        withdrawalTaxRate = _withdrawalTaxRate;
        emit TaxRateUpdated(withdrawalTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override withdraw function to withhold tax on withdrawals
    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);

        // Calculate and withhold withdrawal tax
        uint256 withdrawalTax = (assets * withdrawalTaxRate) / 10000;
        _withholdTax(owner, withdrawalTax);

        return shares;
    }

    // Internal function to withhold tax
    function _withholdTax(address investor, uint256 withdrawalTax) internal {
        if (withdrawalTax > 0) {
            IERC20(asset()).transferFrom(investor, taxAuthority, withdrawalTax);
            emit TaxWithheld(investor, withdrawalTax, taxAuthority);
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

    // Function to get the current tax rate
    function getWithdrawalTaxRate() external view returns (uint256) {
        return withdrawalTaxRate;
    }
}
