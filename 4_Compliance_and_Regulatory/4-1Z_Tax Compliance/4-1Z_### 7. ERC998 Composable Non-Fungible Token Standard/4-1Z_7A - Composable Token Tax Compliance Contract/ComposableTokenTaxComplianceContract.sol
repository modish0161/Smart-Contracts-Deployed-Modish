// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ComposableTokenTaxComplianceContract is ERC998TopDown, ERC721Enumerable, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for tax compliance officers to manage tax settings and submissions
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Struct for holding tax rate information (in basis points, where 10000 = 100%)
    struct TaxRate {
        uint256 parentTaxRate;
        uint256 childTaxRate;
    }

    // Mapping to store tax rates for each token type
    mapping(uint256 => TaxRate) public tokenTaxRates;

    // Address of the tax authority for remittance
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxRateUpdated(uint256 indexed tokenId, uint256 parentTaxRate, uint256 childTaxRate, address updatedBy);
    event TaxWithheld(uint256 indexed tokenId, uint256 parentTax, uint256 childTax, address indexed taxAuthority);
    event TaxAuthorityUpdated(address oldTaxAuthority, address newTaxAuthority);

    constructor(
        string memory name,
        string memory symbol,
        address initialTaxAuthority
    ) ERC998TopDown(name, symbol) {
        require(initialTaxAuthority != address(0), "Invalid tax authority address");
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

    // Function to set the tax rates for a specific token (only by compliance officers)
    function setTaxRates(uint256 tokenId, uint256 parentTaxRate, uint256 childTaxRate) external onlyComplianceOfficer {
        require(parentTaxRate <= 10000 && childTaxRate <= 10000, "Invalid tax rate");
        tokenTaxRates[tokenId] = TaxRate(parentTaxRate, childTaxRate);
        emit TaxRateUpdated(tokenId, parentTaxRate, childTaxRate, msg.sender);
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address newTaxAuthority) external onlyOwner {
        require(newTaxAuthority != address(0), "Invalid tax authority address");
        address oldTaxAuthority = taxAuthority;
        taxAuthority = newTaxAuthority;
        emit TaxAuthorityUpdated(oldTaxAuthority, newTaxAuthority);
    }

    // Override safeTransferFrom function to withhold tax on token transfers
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override nonReentrant whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);

        // Calculate and withhold tax on token transfer
        _withholdTax(from, tokenId);
    }

    // Internal function to calculate and withhold tax
    function _withholdTax(address from, uint256 tokenId) internal {
        TaxRate memory rate = tokenTaxRates[tokenId];
        uint256 parentTax = (rate.parentTaxRate * 10**18) / 10000; // Assuming base is 10**18 for parent token value
        uint256 childTax = (rate.childTaxRate * 10**18) / 10000; // Assuming base is 10**18 for child token value

        // Transfer parent token tax to tax authority
        if (parentTax > 0) {
            payable(taxAuthority).transfer(parentTax);
        }

        // Transfer child token tax to tax authority
        if (childTax > 0) {
            payable(taxAuthority).transfer(childTax);
        }

        emit TaxWithheld(tokenId, parentTax, childTax, taxAuthority);
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

    // Function to get the current tax rates for a token
    function getTaxRates(uint256 tokenId) external view returns (uint256 parentTaxRate, uint256 childTaxRate) {
        TaxRate memory rate = tokenTaxRates[tokenId];
        return (rate.parentTaxRate, rate.childTaxRate);
    }

    // Override _beforeTokenTransfer hook for ERC721Enumerable compliance
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC998TopDown, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Required function overrides for ERC998 and ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC998TopDown, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
