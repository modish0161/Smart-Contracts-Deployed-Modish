// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Tax Withholding Contract
/// @notice This contract automatically calculates and withholds taxes on dividends or token transactions, ensuring tax compliance for equity token holders.
contract TaxWithholding is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TAX_ADMIN_ROLE = keccak256("TAX_ADMIN_ROLE");

    // Struct to store tax information
    struct TaxRate {
        uint256 rate; // Tax rate in percentage (e.g., 10% = 1000, where 10000 = 100%)
        bool isActive;
    }

    // Mapping for tax rates per jurisdiction
    mapping(string => TaxRate) public taxRates;

    // Mapping for user jurisdictions
    mapping(address => string) public userJurisdictions;

    // Events
    event TaxRateSet(string indexed jurisdiction, uint256 rate);
    event JurisdictionSet(address indexed user, string jurisdiction);
    event TaxWithheld(address indexed user, uint256 amount, string jurisdiction);

    /// @notice Constructor to initialize the ERC20 token with details
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    /// @param initialSupply Initial supply of tokens to be minted to the deployer
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TAX_ADMIN_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /// @notice Set the tax rate for a specific jurisdiction
    /// @param jurisdiction The name of the jurisdiction (e.g., "US", "UK")
    /// @param rate Tax rate in percentage (e.g., 10% = 1000)
    function setTaxRate(string memory jurisdiction, uint256 rate) external onlyRole(TAX_ADMIN_ROLE) {
        require(rate <= 10000, "Rate exceeds 100%");
        taxRates[jurisdiction] = TaxRate({rate: rate, isActive: true});
        emit TaxRateSet(jurisdiction, rate);
    }

    /// @notice Set the jurisdiction for a user
    /// @param user The address of the user
    /// @param jurisdiction The jurisdiction for the user
    function setJurisdiction(address user, string memory jurisdiction) external onlyRole(TAX_ADMIN_ROLE) {
        userJurisdictions[user] = jurisdiction;
        emit JurisdictionSet(user, jurisdiction);
    }

    /// @notice Transfer function overridden to calculate and withhold taxes
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _withholdTax(msg.sender, amount);
        return super.transfer(recipient, amount);
    }

    /// @notice TransferFrom function overridden to calculate and withhold taxes
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to transfer
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _withholdTax(sender, amount);
        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Internal function to calculate and withhold taxes
    /// @param user Address of the user whose tokens are being transferred
    /// @param amount Amount of tokens being transferred
    function _withholdTax(address user, uint256 amount) internal {
        string memory jurisdiction = userJurisdictions[user];
        TaxRate memory rateInfo = taxRates[jurisdiction];

        require(rateInfo.isActive, "Jurisdiction tax rate not active");

        uint256 taxAmount = (amount * rateInfo.rate) / 10000;
        if (taxAmount > 0) {
            _burn(user, taxAmount); // Burn tax tokens to simulate withholding
            emit TaxWithheld(user, taxAmount, jurisdiction);
        }
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Mint new tokens (only by admin)
    /// @param account Address to mint the tokens to
    /// @param amount Amount of tokens to mint
    function mint(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(account, amount);
    }

    /// @notice Burn tokens (only by admin)
    /// @param account Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burn(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }
}
