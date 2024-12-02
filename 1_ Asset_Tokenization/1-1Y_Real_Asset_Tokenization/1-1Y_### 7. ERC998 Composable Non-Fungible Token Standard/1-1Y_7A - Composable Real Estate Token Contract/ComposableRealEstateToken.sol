// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Composable Real Estate Token Contract
/// @notice This contract tokenizes real estate properties composed of multiple units or components.
///         It uses the ERC998 standard to allow ownership and transfer of whole property sets or individual components.
contract ComposableRealEstateToken is ERC998TopDown, Ownable, ReentrancyGuard {
    
    struct PropertyComponent {
        string name;
        uint256 value;
        address owner;
    }

    // Mapping of property IDs to components
    mapping(uint256 => PropertyComponent[]) public propertyComponents;

    // Event emitted when a new property is tokenized
    event PropertyTokenized(uint256 indexed propertyId, string name, uint256 value);
    
    // Event emitted when a component is added to a property
    event ComponentAdded(uint256 indexed propertyId, string componentName, uint256 componentValue);

    // Constructor to set the name and symbol for the composable real estate token
    constructor() ERC721("Composable Real Estate Token", "CRET") {}

    /// @notice Tokenize a new real estate property with its components
    /// @param propertyId The ID of the new property
    /// @param name The name of the property
    /// @param value The value of the property
    /// @param componentNames Names of the components that make up the property
    /// @param componentValues Values of each component in the property
    function tokenizeProperty(
        uint256 propertyId,
        string memory name,
        uint256 value,
        string[] memory componentNames,
        uint256[] memory componentValues
    ) public onlyOwner nonReentrant {
        require(componentNames.length == componentValues.length, "Components data mismatch");

        // Mint the top-level ERC998 token for the property
        _mint(msg.sender, propertyId);

        // Add components to the property
        for (uint256 i = 0; i < componentNames.length; i++) {
            propertyComponents[propertyId].push(PropertyComponent({
                name: componentNames[i],
                value: componentValues[i],
                owner: msg.sender
            }));

            emit ComponentAdded(propertyId, componentNames[i], componentValues[i]);
        }

        emit PropertyTokenized(propertyId, name, value);
    }

    /// @notice Transfer ownership of a component within a property
    /// @param propertyId The ID of the property containing the component
    /// @param componentIndex The index of the component to transfer
    /// @param newOwner The address of the new owner of the component
    function transferComponent(
        uint256 propertyId,
        uint256 componentIndex,
        address newOwner
    ) public {
        require(ownerOf(propertyId) == msg.sender, "You do not own this property");
        require(componentIndex < propertyComponents[propertyId].length, "Invalid component index");

        // Transfer ownership of the component
        propertyComponents[propertyId][componentIndex].owner = newOwner;
    }

    /// @notice Get details of a component within a property
    /// @param propertyId The ID of the property
    /// @param componentIndex The index of the component to view
    /// @return name Name of the component
    /// @return value Value of the component
    /// @return owner Owner of the component
    function getComponentDetails(
        uint256 propertyId,
        uint256 componentIndex
    ) public view returns (string memory name, uint256 value, address owner) {
        require(componentIndex < propertyComponents[propertyId].length, "Invalid component index");
        
        PropertyComponent memory component = propertyComponents[propertyId][componentIndex];
        return (component.name, component.value, component.owner);
    }

    /// @notice Get the total number of components in a property
    /// @param propertyId The ID of the property
    /// @return The number of components in the property
    function getComponentCount(uint256 propertyId) public view returns (uint256) {
        return propertyComponents[propertyId].length;
    }

    /// @notice Override ERC721's transfer function to prevent transferring properties with sub-components directly
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        require(propertyComponents[tokenId].length == 0, "Cannot transfer a property with components");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
