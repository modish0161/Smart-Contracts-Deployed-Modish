### Smart Contract: `MixedCommodityTokenization.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Mixed Commodity Tokenization Contract
/// @notice This contract tokenizes a portfolio of different commodities, where each ERC1155 token represents a unique commodity.
/// @dev Uses the ERC1155 standard to manage multiple commodities within a single contract.
contract MixedCommodityTokenization is ERC1155, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMMODITY_MANAGER_ROLE = keccak256("COMMODITY_MANAGER_ROLE");

    // Counter for token IDs
    Counters.Counter private _tokenIdCounter;

    // Mapping to store commodity information
    struct Commodity {
        uint256 id;
        string name;
        uint256 totalSupply;
        uint256 pricePerUnit; // Price per unit in wei
    }
    mapping(uint256 => Commodity) private _commodities;

    // Events
    event CommodityTokenized(uint256 indexed tokenId, string name, uint256 totalSupply, uint256 pricePerUnit);
    event CommodityMinted(uint256 indexed tokenId, address indexed to, uint256 amount);
    event CommodityBurned(uint256 indexed tokenId, address indexed from, uint256 amount);
    event CommodityTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event CommodityPurchased(uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalPrice);

    /// @dev Constructor to set up the initial values and roles
    /// @param uri Base URI for all token types
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(COMMODITY_MANAGER_ROLE, msg.sender);
    }

    /// @notice Function to create a new commodity
    /// @param name Name of the commodity (e.g., Gold, Silver, Oil)
    /// @param totalSupply Total supply of the commodity tokens
    /// @param pricePerUnit Price per unit in wei
    /// @param uri Metadata URI for the commodity token
    /// @dev Only an account with the COMMODITY_MANAGER_ROLE can call this function
    function tokenizeCommodity(
        string memory name,
        uint256 totalSupply,
        uint256 pricePerUnit,
        string memory uri
    ) external onlyRole(COMMODITY_MANAGER_ROLE) whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _setURI(uri);
        _commodities[tokenId] = Commodity(tokenId, name, totalSupply, pricePerUnit);

        emit CommodityTokenized(tokenId, name, totalSupply, pricePerUnit);
    }

    /// @notice Function to mint tokens for a commodity
    /// @param to Address to mint tokens to
    /// @param tokenId ID of the token to mint
    /// @param amount Amount of tokens to mint
    /// @dev Only an account with the COMMODITY_MANAGER_ROLE can call this function
    function mintCommodity(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(COMMODITY_MANAGER_ROLE) whenNotPaused {
        require(_commodities[tokenId].totalSupply > 0, "Commodity does not exist");
        _mint(to, tokenId, amount, "");
        emit CommodityMinted(tokenId, to, amount);
    }

    /// @notice Function to burn tokens of a commodity
    /// @param from Address to burn tokens from
    /// @param tokenId ID of the token to burn
    /// @param amount Amount of tokens to burn
    /// @dev Only an account with the COMMODITY_MANAGER_ROLE can call this function
    function burnCommodity(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(COMMODITY_MANAGER_ROLE) whenNotPaused {
        require(_commodities[tokenId].totalSupply > 0, "Commodity does not exist");
        _burn(from, tokenId, amount);
        emit CommodityBurned(tokenId, from, amount);
    }

    /// @notice Function to transfer tokens of a commodity
    /// @param from Address to transfer tokens from
    /// @param to Address to transfer tokens to
    /// @param tokenId ID of the token to transfer
    /// @param amount Amount of tokens to transfer
    /// @dev Can be called by any user with sufficient balance of the token
    function transferCommodity(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        require(balanceOf(from, tokenId) >= amount, "Insufficient balance to transfer");
        safeTransferFrom(from, to, tokenId, amount, "");
        emit CommodityTransferred(tokenId, from, to, amount);
    }

    /// @notice Function to purchase tokens of a commodity
    /// @param tokenId ID of the token to purchase
    /// @param amount Amount of tokens to purchase
    /// @dev Buyer must send enough ether to cover the price of the tokens
    function purchaseCommodity(uint256 tokenId, uint256 amount) external payable nonReentrant whenNotPaused {
        require(_commodities[tokenId].totalSupply > 0, "Commodity does not exist");
        uint256 totalPrice = _commodities[tokenId].pricePerUnit * amount;
        require(msg.value >= totalPrice, "Insufficient funds to purchase");

        _mint(msg.sender, tokenId, amount, "");
        emit CommodityPurchased(tokenId, msg.sender, amount, totalPrice);
    }

    /// @notice Function to get commodity details
    /// @param tokenId ID of the commodity token
    /// @return Commodity structure with all details
    function getCommodityDetails(uint256 tokenId) external view returns (Commodity memory) {
        require(_commodities[tokenId].totalSupply > 0, "Commodity does not exist");
        return _commodities[tokenId];
    }

    /// @notice Function to withdraw funds from the contract
    /// @dev Only the owner can withdraw the funds
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Function to pause the contract
    /// @dev Only accounts with ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract
    /// @dev Only accounts with ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

### Key Features of the Contract:

1. **ERC1155 Tokenization of Mixed Commodities**:
   - Each ERC1155 token can represent a different commodity (e.g., gold, silver, oil).
   - Allows for diverse portfolios of commodities, simplifying management and trading.

2. **Commodity Management**:
   - `tokenizeCommodity`: Creates a new commodity with its own token, representing a specific commodity with a defined total supply and price.
   - `mintCommodity`: Mints additional tokens for a given commodity, increasing the supply.
   - `burnCommodity`: Burns tokens of a given commodity, reducing the supply.
   - `transferCommodity`: Transfers commodity tokens between addresses, enabling trading.
   - `purchaseCommodity`: Allows users to purchase commodity tokens with ether, based on the defined price per unit.

3. **Role-Based Access Control**:
   - **ADMIN_ROLE**: Admins can pause and unpause the contract.
   - **COMMODITY_MANAGER_ROLE**: Commodity managers can create, mint, and burn commodity tokens.

4. **Pausing and Security**:
   - The contract can be paused and unpaused by accounts with the `ADMIN_ROLE`.
   - `Pausable`: Allows freezing of contract functionalities in case of emergency.
   - `ReentrancyGuard`: Prevents reentrancy attacks during transfer and purchase functions.

5. **Event Logging**:
   - `CommodityTokenized`: Emitted when a new commodity is created.
   - `CommodityMinted`: Emitted when new tokens are minted for a commodity.
   - `CommodityBurned`: Emitted when tokens are burned.
   - `CommodityTransferred`: Emitted when tokens are transferred between addresses.
   - `CommodityPurchased`: Emitted when tokens are purchased.

6. **Commodity Information Access**:
   - `getCommodityDetails`: Allows querying the details of a specific commodity token, including its attributes and total supply.

7. **Funds Management**:
   - `withdrawFunds`: Allows the owner to withdraw the ether held by the contract.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin contracts installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script for the contract:
  