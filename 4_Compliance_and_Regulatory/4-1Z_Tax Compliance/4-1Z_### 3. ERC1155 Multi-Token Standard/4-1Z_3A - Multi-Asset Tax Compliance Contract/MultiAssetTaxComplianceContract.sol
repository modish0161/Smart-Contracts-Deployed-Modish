// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiAssetTaxComplianceContract is ERC1155, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role for designated operators (e.g., compliance officers)
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Mapping for storing tax rates for different token types
    mapping(uint256 => uint256) private _taxRates; // tokenId => taxRate (in basis points, e.g., 500 = 5%)

    // Address where collected taxes will be sent
    address public taxAuthority;

    // Events for tracking tax operations
    event TaxWithheld(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount, uint256 taxAmount, uint256 timestamp);
    event TaxRateUpdated(uint256 indexed tokenId, uint256 newTaxRate, address updatedBy);
    event TaxAuthorityUpdated(address newTaxAuthority, address updatedBy);

    constructor(
        string memory uri,
        address _taxAuthority
    ) ERC1155(uri) {
        require(_taxAuthority != address(0), "Invalid tax authority address");

        taxAuthority = _taxAuthority;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    // Function to set a new tax rate for a specific token type (only operator)
    function setTaxRate(uint256 tokenId, uint256 taxRate) external onlyRole(OPERATOR_ROLE) {
        require(taxRate <= 10000, "Tax rate should be less than or equal to 100%");
        _taxRates[tokenId] = taxRate;
        emit TaxRateUpdated(tokenId, taxRate, msg.sender);
    }

    // Function to get the tax rate of a specific token type
    function getTaxRate(uint256 tokenId) external view returns (uint256) {
        return _taxRates[tokenId];
    }

    // Function to set a new tax authority address (only owner)
    function setTaxAuthority(address _taxAuthority) external onlyOwner {
        require(_taxAuthority != address(0), "Invalid tax authority address");
        taxAuthority = _taxAuthority;
        emit TaxAuthorityUpdated(_taxAuthority, msg.sender);
    }

    // Overridden safeTransferFrom function to include tax calculation and real-time reporting
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override whenNotPaused {
        uint256 taxAmount = (amount * _taxRates[id]) / 10000;
        uint256 amountAfterTax = amount - taxAmount;

        super.safeTransferFrom(from, to, id, amountAfterTax, data);
        if (taxAmount > 0) {
            super.safeTransferFrom(from, taxAuthority, id, taxAmount, data);
            emit TaxWithheld(id, from, to, amount, taxAmount, block.timestamp);
        }
    }

    // Overridden safeBatchTransferFrom function to include tax calculation and real-time reporting
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenNotPaused {
        uint256[] memory amountsAfterTax = new uint256[](ids.length);
        uint256[] memory taxAmounts = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            taxAmounts[i] = (amounts[i] * _taxRates[ids[i]]) / 10000;
            amountsAfterTax[i] = amounts[i] - taxAmounts[i];
        }

        super.safeBatchTransferFrom(from, to, ids, amountsAfterTax, data);

        for (uint256 i = 0; i < ids.length; i++) {
            if (taxAmounts[i] > 0) {
                super.safeBatchTransferFrom(from, taxAuthority, _asSingletonArray(ids[i]), _asSingletonArray(taxAmounts[i]), data);
                emit TaxWithheld(ids[i], from, to, amounts[i], taxAmounts[i], block.timestamp);
            }
        }
    }

    // Utility function to convert a single value into a single-item array
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    // Function to add an operator (only owner)
    function addOperator(address operator) external onlyOwner {
        grantRole(OPERATOR_ROLE, operator);
    }

    // Function to remove an operator (only owner)
    function removeOperator(address operator) external onlyOwner {
        revokeRole(OPERATOR_ROLE, operator);
    }

    // Function to pause all token transfers (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause all token transfers (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }
}
