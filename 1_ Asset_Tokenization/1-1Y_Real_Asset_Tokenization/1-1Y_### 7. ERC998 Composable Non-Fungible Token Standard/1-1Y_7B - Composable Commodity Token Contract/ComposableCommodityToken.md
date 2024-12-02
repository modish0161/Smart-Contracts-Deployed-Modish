### Smart Contract: `ComposableCommodityToken.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Composable Commodity Token Contract
/// @notice This contract tokenizes bundles of commodities using the ERC998 standard, allowing the ownership and transfer of entire bundles or individual components.
contract ComposableCommodityToken is ERC998TopDown, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    
    struct CommodityComponent {
        string name;
        uint256 value;
        address owner;
    }

    // Mapping of commodity bundle IDs to their components
    mapping(uint256 => CommodityComponent[]) public commodityComponents;

    // Event emitted when a new commodity bundle is created
    event CommodityBundleCreated(uint256 indexed bundleId, string name, uint256 totalValue);

    // Event emitted when a component is added to a commodity bundle
    event ComponentAdded(uint256 indexed bundleId, string componentName, uint256 componentValue);

    // Constructor to set the name and symbol for the composable commodity token
    constructor() ERC721("Composable Commodity Token", "CCT") {}

    /// @notice Create a new commodity bundle with multiple components
    /// @param bundleId The ID of the new commodity bundle
    /// @param name The name of the commodity bundle
    /// @param componentNames Names of the components in the bundle
    /// @param componentValues Values of each component in the bundle
    /// @param uri Metadata URI for the bundle
    function createCommodityBundle(
        uint256 bundleId,
        string memory name,
        string[] memory componentNames,
        uint256[] memory componentValues,
        string memory uri
    ) public onlyOwner nonReentrant {
        require(componentNames.length == componentValues.length, "Components data mismatch");

        // Mint the top-level ERC998 token for the commodity bundle
        _mint(msg.sender, bundleId);
        _setTokenURI(bundleId, uri);

        uint256 totalValue = 0;

        // Add components to the commodity bundle
        for (uint256 i = 0; i < componentNames.length; i++) {
            commodityComponents[bundleId].push(CommodityComponent({
                name: componentNames[i],
                value: componentValues[i],
                owner: msg.sender
            }));

            totalValue += componentValues[i];

            emit ComponentAdded(bundleId, componentNames[i], componentValues[i]);
        }

        emit CommodityBundleCreated(bundleId, name, totalValue);
    }

    /// @notice Transfer ownership of a component within a commodity bundle
    /// @param bundleId The ID of the commodity bundle containing the component
    /// @param componentIndex The index of the component to transfer
    /// @param newOwner The address of the new owner of the component
    function transferComponent(
        uint256 bundleId,
        uint256 componentIndex,
        address newOwner
    ) public {
        require(ownerOf(bundleId) == msg.sender, "You do not own this bundle");
        require(componentIndex < commodityComponents[bundleId].length, "Invalid component index");

        // Transfer ownership of the component
        commodityComponents[bundleId][componentIndex].owner = newOwner;
    }

    /// @notice Get details of a component within a commodity bundle
    /// @param bundleId The ID of the commodity bundle
    /// @param componentIndex The index of the component to view
    /// @return name Name of the component
    /// @return value Value of the component
    /// @return owner Owner of the component
    function getComponentDetails(
        uint256 bundleId,
        uint256 componentIndex
    ) public view returns (string memory name, uint256 value, address owner) {
        require(componentIndex < commodityComponents[bundleId].length, "Invalid component index");
        
        CommodityComponent memory component = commodityComponents[bundleId][componentIndex];
        return (component.name, component.value, component.owner);
    }

    /// @notice Get the total number of components in a commodity bundle
    /// @param bundleId The ID of the commodity bundle
    /// @return The number of components in the bundle
    function getComponentCount(uint256 bundleId) public view returns (uint256) {
        return commodityComponents[bundleId].length;
    }

    /// @notice Override ERC721's transfer function to prevent transferring bundles with sub-components directly
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        require(commodityComponents[tokenId].length == 0, "Cannot transfer a bundle with components");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Support for both ERC721 and ERC998 interfaces
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC998TopDown) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Override required functions for URI storage
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
```

### Key Features of the Contract:

1. **ERC998 Composable Non-Fungible Tokens**:
   - Uses the ERC998 standard to allow composition of multiple commodity components (e.g., gold, silver, oil) into a single tokenized bundle.
   - Enables ownership and transfer of entire commodity bundles or individual components.

2. **Commodity Bundle and Component Structure**:
   - Commodity bundles are tokenized into ERC998 tokens.
   - Each bundle can have multiple components, each with its own value and ownership.
   - The components are managed through the `CommodityComponent` struct, which stores the name, value, and owner of each component.

3. **Component Ownership and Transfer**:
   - Ownership of individual components within a commodity bundle can be transferred without affecting the ownership of the whole bundle.
   - `transferComponent` allows owners to transfer individual components to new owners.

4. **Commodity Bundle Creation**:
   - The contract allows the creation of new commodity bundles through the `createCommodityBundle` function, which creates a top-level ERC998 token representing the bundle and its components.
   - Bundle details such as name, value, components, and metadata URI are stored within the contract.

5. **Access Control**:
   - Only the contract owner can create new commodity bundles.
   - Bundle owners can transfer ownership of individual components.

6. **Events**:
   - Events `CommodityBundleCreated` and `ComponentAdded` are emitted to track the creation of new commodity bundles and the addition of components.

7. **ERC721 Compliance**:
   - The contract extends the ERC721 standard and incorporates ERC721Enumerable and ERC721URIStorage for additional functionality like token enumeration and metadata URI management.
   - It overrides ERC721's transfer functions to prevent direct transfer of bundles with components.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure OpenZeppelin contracts are installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script using Hardhat or Truffle:

   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     // Deploy the contract
     const ComposableCommodityToken = await ethers.getContractFactory("ComposableCommodityToken");
     const composableCommodityToken = await ComposableCommodityToken.deploy();

     console.log("Composable Commodity Token Contract deployed to:", composableCommodityToken.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Verification**:
   - Write unit tests to verify the core functionalities such as bundle creation, component management, and ownership transfers.
   - Perform a security audit to ensure safe handling of commodity components and ownership.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Upgradability**: You can add upgradeable contract patterns using OpenZeppelin's `UUPS Proxy` for future enhancements.
- **Compliance**: Consider integrating KYC/AML verification for compliant transfers of commodity components.
- **DeFi Integration**: If needed, extend the contract to enable staking of commodity tokens for yield or liquidity provision in decentralized finance (DeFi) protocols.

This contract provides a secure and modular solution for tokenizing bundles of commodities, with flexible ownership transfer functionality based on the ERC998 standard.