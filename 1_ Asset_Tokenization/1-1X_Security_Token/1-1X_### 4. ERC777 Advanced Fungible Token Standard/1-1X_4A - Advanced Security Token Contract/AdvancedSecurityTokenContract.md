Here is a Solidity smart contract code for the `AdvancedSecurityTokenContract.sol` using the ERC777 standard. This contract includes enhanced functionalities like token minting, burning, and operator permissions, giving issuers greater control over token movements and actions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Advanced Security Token Contract
/// @notice ERC777 token with enhanced functionalities like minting, burning, and operator permissions.
contract AdvancedSecurityTokenContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount);

    // Event emitted when tokens are burned
    event TokensBurned(address indexed from, uint256 amount);

    /// @notice Constructor to initialize the ERC777 token
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param defaultOperators_ List of default operators
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) ERC777(name_, symbol_, defaultOperators_) {
        // Grant the contract deployer the default admin, minter, and burner roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /// @notice Mint new tokens
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    /// @dev Only accounts with the MINTER_ROLE can mint tokens
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused nonReentrant {
        _mint(to, amount, "", "");
        emit TokensMinted(to, amount);
    }

    /// @notice Burn tokens
    /// @param amount Amount of tokens to burn
    /// @dev Only accounts with the BURNER_ROLE can burn tokens
    function burn(uint256 amount) public onlyRole(BURNER_ROLE) whenNotPaused nonReentrant {
        _burn(msg.sender, amount, "", "");
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Burn tokens from a specified address
    /// @param from Address from which tokens will be burned
    /// @param amount Amount of tokens to burn
    /// @dev Only accounts with the BURNER_ROLE can burn tokens from other accounts
    function burnFrom(address from, uint256 amount) public onlyRole(BURNER_ROLE) whenNotPaused nonReentrant {
        require(isOperatorFor(msg.sender, from), "Caller is not an operator for the account");
        _burn(from, amount, "", "");
        emit TokensBurned(from, amount);
    }

    /// @notice Pause the contract
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can pause the contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can unpause the contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Override transfer function to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Assign operator role to an address
    /// @param operator Address to assign the operator role to
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can assign the operator role
    function assignOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
    }

    /// @notice Revoke operator role from an address
    /// @param operator Address to revoke the operator role from
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can revoke the operator role
    function revokeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
    }

    /// @notice Check if an address has operator role
    /// @param operator Address to check for the operator role
    /// @return true if the address has the operator role, false otherwise
    function isOperator(address operator) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, operator);
    }
}
```

### **Key Functionalities**:

1. **Minting**:
   - Allows accounts with the `MINTER_ROLE` to mint new tokens.
   - Emits a `TokensMinted` event on successful minting.

2. **Burning**:
   - Accounts with the `BURNER_ROLE` can burn their own tokens or tokens from other accounts if they are operators for that account.
   - Emits a `TokensBurned` event when tokens are burned.

3. **Operator Management**:
   - Accounts with the `DEFAULT_ADMIN_ROLE` can assign or revoke the `OPERATOR_ROLE` to other accounts.
   - Allows operators to perform specific actions on behalf of token holders.

4. **Pause and Unpause**:
   - Accounts with the `DEFAULT_ADMIN_ROLE` can pause or unpause the contract, preventing all token transfers during the pause period.

5. **Security and Compliance**:
   - Uses `AccessControl` for fine-grained role management.
   - Includes `Pausable` and `ReentrancyGuard` to enhance security and prevent reentrancy attacks.

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
       console.log("Deploying contracts with the account:", deployer.address);

       const AdvancedSecurityTokenContract = await ethers.getContractFactory("AdvancedSecurityTokenContract");
       const token = await AdvancedSecurityTokenContract.deploy(
           "AdvancedSecurityToken", // Token name
           "AST", // Token symbol
           [] // Default operators
       );

       console.log("AdvancedSecurityTokenContract deployed to:", token.address);
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
   npx hardhat verify --network mainnet <deployed_contract_address> "AdvancedSecurityToken" "AST" []
   ```

### **Further Customization**:

1. **Operator Restrictions**: Implement additional restrictions on operators, such as limiting the number of tokens they can operate on.
2. **KYC/AML Compliance**: Integrate with a third-party KYC/AML service to restrict operator actions and ensure only verified accounts can perform certain actions.
3. **Governance Integration**: Include on-chain governance to allow token holders to vote on operator assignments and other key decisions.
4. **Multi-Network Deployment**: Deploy the contract on multiple networks such as Ethereum, BSC, or Layer-2 solutions like Polygon or Arbitrum.

This contract provides a robust foundation for an advanced security token using the ERC777 standard. It should be rigorously tested and audited before being deployed in a production environment.