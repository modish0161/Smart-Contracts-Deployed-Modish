### Smart Contract: `CommodityTokenizationContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Commodity Tokenization Contract
/// @notice Tokenizes divisible physical commodities like gold, silver, oil, or natural gas.
/// @dev Implements ERC20 with additional compliance, security, and administrative controls.
contract CommodityTokenizationContract is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Roles for Access Control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");

    // Whitelist for KYC/AML compliance
    mapping(address => bool) private _whitelisted;

    // Events
    event InvestorWhitelisted(address indexed investor);
    event InvestorRemoved(address indexed investor);
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    /// @dev Constructor that initializes the ERC20 token with name and symbol
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialSupply Initial supply of tokens
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);  // Mint initial supply to contract deployer
    }

    /// @notice Adds an investor to the whitelist
    /// @param investor Address of the investor
    /// @dev Only ADMIN_ROLE can whitelist investors
    function addWhitelistedInvestor(address investor) external onlyRole(ADMIN_ROLE) {
        require(!_whitelisted[investor], "Investor already whitelisted");
        _whitelisted[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    /// @notice Removes an investor from the whitelist
    /// @param investor Address of the investor
    /// @dev Only ADMIN_ROLE can remove investors from the whitelist
    function removeWhitelistedInvestor(address investor) external onlyRole(ADMIN_ROLE) {
        require(_whitelisted[investor], "Investor not whitelisted");
        _whitelisted[investor] = false;
        emit InvestorRemoved(investor);
    }

    /// @notice Checks if an investor is whitelisted
    /// @param investor Address of the investor
    /// @return Boolean indicating if the investor is whitelisted
    function isWhitelisted(address investor) public view returns (bool) {
        return _whitelisted[investor];
    }

    /// @notice Mints tokens to a specified address
    /// @param to Address to receive the minted tokens
    /// @param amount Number of tokens to mint
    /// @dev Only ADMIN_ROLE can mint tokens and recipient must be whitelisted
    function mint(address to, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(_whitelisted[to], "Recipient must be whitelisted");
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }

    /// @notice Burns tokens from a specified address
    /// @param from Address to burn the tokens from
    /// @param amount Number of tokens to burn
    /// @dev Only ADMIN_ROLE can burn tokens from whitelisted investors
    function burn(address from, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(_whitelisted[from], "Address must be whitelisted");
        _burn(from, amount);
        emit TokenBurned(from, amount);
    }

    /// @notice Pauses all token transfers
    /// @dev Only ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses all token transfers
    /// @dev Only ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override for ERC20 transfer with pause and whitelisting functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        require(_whitelisted[from], "Sender must be whitelisted");
        require(_whitelisted[to], "Recipient must be whitelisted");
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

### Key Features of the Contract:

1. **ERC20 Fungible Token Standard**:
   - The contract follows the ERC20 standard for representing divisible assets like commodities.
   - Supports fractional ownership of assets like gold, silver, oil, etc.

2. **Investor Whitelisting**:
   - `addWhitelistedInvestor` and `removeWhitelistedInvestor`: Functions to manage a whitelist of approved investors for compliance.
   - `isWhitelisted`: Public view function to check if an address is whitelisted.

3. **Token Minting and Burning**:
   - `mint`: Allows the administrator to mint new tokens to a whitelisted address.
   - `burn`: Allows the administrator to burn tokens from a whitelisted address.

4. **Pausable**:
   - Contract can be paused and unpaused by the administrator using `pause` and `unpause` functions.

5. **Access Control**:
   - Roles for administrators and regulators:
     - **ADMIN_ROLE**: Manages whitelisting, token minting, burning, and pausing.
     - **REGULATOR_ROLE**: Additional roles can be added for regulatory control as needed.

6. **Event Logging**:
   - `InvestorWhitelisted`: Emitted when an investor is whitelisted.
   - `InvestorRemoved`: Emitted when an investor is removed from the whitelist.
   - `TokenMinted`: Emitted when tokens are minted to an address.
   - `TokenBurned`: Emitted when tokens are burned from an address.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure OpenZeppelin contracts are installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the contract using Hardhat or Truffle:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script for Hardhat or Truffle. Example:

   ```javascript
   // deployment script using Hardhat

   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const CommodityTokenizationContract = await ethers.getContractFactory("CommodityTokenizationContract");
     const commodityToken = await CommodityTokenizationContract.deploy("Commodity Token", "COMT", ethers.utils.parseUnits("1000000", 18));

     console.log("Commodity Tokenization Contract deployed to:", commodityToken.address);
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
   - Write unit tests to verify functionalities such as whitelisting, token transfers, minting, burning, and pausing.
   - Run gas profiling to ensure efficiency.
   - Conduct security audits using tools like MythX or CertiK.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for integration and maintenance.

This contract is ready for deployment and testing based on your specifications. Further customization and optimization can be applied as per your requirements.