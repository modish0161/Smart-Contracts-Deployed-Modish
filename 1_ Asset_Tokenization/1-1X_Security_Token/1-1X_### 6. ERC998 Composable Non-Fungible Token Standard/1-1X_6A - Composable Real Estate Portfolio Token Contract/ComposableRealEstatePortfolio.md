Here's a smart contract for a "Composable Real Estate Portfolio Token Contract" using the ERC998 standard. This contract allows the creation of a composable NFT that can own other ERC721 tokens, representing individual real estate properties or asset components. The main NFT represents the portfolio of real estate assets, and each sub-NFT represents an individual property.

### Contract Code: `ComposableRealEstatePortfolio.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Composable Real Estate Portfolio Token Contract
/// @dev ERC998 composable NFT contract for managing portfolios of real estate assets, each represented as ERC721 tokens.
contract ComposableRealEstatePortfolio is ERC721Enumerable, Ownable, AccessControl, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _portfolioIds;

    // Role definitions for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Mapping from portfolio ID to owned ERC721 tokens and their counts
    mapping(uint256 => mapping(address => uint256[])) private _ownedERC721Tokens;

    /// @dev Event emitted when a new portfolio token is minted
    event PortfolioTokenMinted(address indexed owner, uint256 indexed portfolioId);

    /// @dev Event emitted when an ERC721 token is added to a portfolio
    event ERC721TokenAdded(uint256 indexed portfolioId, address indexed erc721Address, uint256 indexed tokenId);

    /// @dev Event emitted when an ERC721 token is removed from a portfolio
    event ERC721TokenRemoved(uint256 indexed portfolioId, address indexed erc721Address, uint256 indexed tokenId);

    /// @notice Constructor to initialize the contract with name and symbol
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Grant the contract deployer the default admin, minter, and pauser roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Mint a new portfolio token
    /// @dev Only accounts with the MINTER_ROLE can mint new tokens
    /// @param to Address of the token owner
    /// @return portfolioId The ID of the newly minted portfolio token
    function mintPortfolioToken(address to) public onlyRole(MINTER_ROLE) whenNotPaused returns (uint256) {
        require(to != address(0), "ComposableRealEstatePortfolio: mint to the zero address");

        _portfolioIds.increment();
        uint256 portfolioId = _portfolioIds.current();

        _mint(to, portfolioId);
        emit PortfolioTokenMinted(to, portfolioId);

        return portfolioId;
    }

    /// @notice Add an ERC721 token to a portfolio
    /// @dev The sender must be the owner of both the portfolio token and the ERC721 token
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to add
    function addERC721ToPortfolio(uint256 portfolioId, address erc721Address, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, portfolioId), "ComposableRealEstatePortfolio: caller is not owner nor approved for portfolio");
        require(IERC721(erc721Address).ownerOf(tokenId) == msg.sender, "ComposableRealEstatePortfolio: caller is not owner of ERC721 token");

        IERC721(erc721Address).transferFrom(msg.sender, address(this), tokenId);
        _ownedERC721Tokens[portfolioId][erc721Address].push(tokenId);

        emit ERC721TokenAdded(portfolioId, erc721Address, tokenId);
    }

    /// @notice Remove an ERC721 token from a portfolio
    /// @dev The sender must be the owner of the portfolio token
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @param tokenId ID of the ERC721 token to remove
    function removeERC721FromPortfolio(uint256 portfolioId, address erc721Address, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, portfolioId), "ComposableRealEstatePortfolio: caller is not owner nor approved for portfolio");

        uint256[] storage tokenIds = _ownedERC721Tokens[portfolioId][erc721Address];
        bool found = false;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                found = true;
                break;
            }
        }
        require(found, "ComposableRealEstatePortfolio: ERC721 token not found in portfolio");

        IERC721(erc721Address).transferFrom(address(this), msg.sender, tokenId);
        emit ERC721TokenRemoved(portfolioId, erc721Address, tokenId);
    }

    /// @notice Get all ERC721 tokens owned by a portfolio
    /// @param portfolioId ID of the portfolio token
    /// @param erc721Address Address of the ERC721 token contract
    /// @return Array of ERC721 token IDs owned by the portfolio
    function getERC721TokensInPortfolio(uint256 portfolioId, address erc721Address) public view returns (uint256[] memory) {
        return _ownedERC721Tokens[portfolioId][erc721Address];
    }

    /// @notice Pause the contract, preventing all token transfers and portfolio modifications
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing token transfers and portfolio modifications
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Override _beforeTokenTransfer to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Check if an address has the MINTER_ROLE
    /// @param account Address to check for the minter role
    /// @return true if the address has the minter role, false otherwise
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /// @notice Check if an address has the PAUSER_ROLE
    /// @param account Address to check for the pauser role
    /// @return true if the address has the pauser role, false otherwise
    function isPauser(address account) public view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }

    /// @notice Add a new minter with the MINTER_ROLE
    /// @param account Address to be granted the minter role
    function addMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /// @notice Remove an existing minter with the MINTER_ROLE
    /// @param account Address to be revoked the minter role
    function removeMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, account);
    }
}
```

### **Key Functionalities**:

1. **Portfolio Minting**:
   - Authorized accounts with the `MINTER_ROLE` can mint new portfolio tokens using the `mintPortfolioToken` function.

2. **ERC721 Token Management**:
   - `addERC721ToPortfolio`: Allows adding an ERC721 token to a specific portfolio.
   - `removeERC721FromPortfolio`: Allows removing an ERC721 token from a specific portfolio.
   - `getERC721TokensInPortfolio`: Retrieves the ERC721 tokens owned by a portfolio.

3. **Role-Based Access Control**:
   - `MINTER_ROLE`: Allows minting new portfolio tokens.
   - `PAUSER_ROLE`: Allows pausing and unpausing the contract.
   - `DEFAULT_ADMIN_ROLE`: Has permissions to manage other roles.

4. **Pause and Unpause**:
   - The contract can be paused or unpaused, preventing or allowing token transfers and portfolio modifications.

5. **Security and Compliance**:
   - Utilizes `AccessControl` for role management.
   - Includes `Pausable` to pause the contract during emergencies.

### **Deployment Instructions**:

1. **Install Dependencies**:
   Ensure OpenZeppelin libraries are installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Use Hardhat or Truffle to compile the contract:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script:
   ```javascript
   async function main() {
       const [deployer] = await ethers.getSigners();
       console.log("Deploying contracts with the account:", deployer

.address);

       const ComposableRealEstatePortfolio = await ethers.getContractFactory("ComposableRealEstatePortfolio");
       const portfolio = await ComposableRealEstatePortfolio.deploy(
           "ComposableRealEstatePortfolio", // Token name
           "CREP" // Token symbol
       );

       console.log("ComposableRealEstatePortfolio deployed to:", portfolio.address);
   }

   main()
       .then(() => process.exit(0))
       .catch(error => {
           console.error(error);
           process.exit(1);
       });
   ```

4. **Run Unit Tests**:
   Write unit tests using Mocha and Chai to verify the functionality of the contract:
   ```bash
   npx hardhat test
   ```

5. **Verify on Etherscan (Optional)**:
   If deploying to a public network, verify the contract on Etherscan using:
   ```bash
   npx hardhat verify --network mainnet <deployed_contract_address> "ComposableRealEstatePortfolio" "CREP"
   ```

### **Further Customization**:

1. **KYC/AML Compliance**:
   Integrate KYC/AML verification to restrict token transfers to approved addresses.

2. **Governance Integration**:
   Implement governance mechanisms to allow token holders to vote on asset management decisions.

3. **Multi-Network Deployment**:
   Deploy the contract on multiple networks such as Ethereum, Binance Smart Chain, or Layer-2 solutions like Polygon.

This contract provides a secure and scalable foundation for tokenizing real estate portfolios using the ERC998 standard. It should be rigorously tested and audited before being deployed in a production environment.