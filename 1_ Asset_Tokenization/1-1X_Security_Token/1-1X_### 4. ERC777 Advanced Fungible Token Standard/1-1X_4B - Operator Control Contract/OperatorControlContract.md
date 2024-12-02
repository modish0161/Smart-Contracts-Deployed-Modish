Here is a Solidity smart contract code for the `OperatorControlContract.sol` using the ERC777 standard. This contract allows an authorized operator to manage and execute transactions on behalf of the security token holders, providing enhanced control and compliance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Operator Control Contract
/// @notice ERC777 token with enhanced operator functionalities, allowing authorized operators to manage transactions on behalf of security token holders.
contract OperatorControlContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Event emitted when an operator performs a controlled transaction
    event OperatorExecuted(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data);

    /// @notice Constructor to initialize the ERC777 token
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param defaultOperators_ List of default operators
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) ERC777(name_, symbol_, defaultOperators_) {
        // Grant the contract deployer the default admin and pauser roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Function for an operator to perform a controlled transaction on behalf of a token holder
    /// @param from Address from which the tokens will be debited
    /// @param to Address to which the tokens will be credited
    /// @param amount Number of tokens to be transferred
    /// @param data Additional data to be logged
    function operatorExecute(address from, address to, uint256 amount, bytes memory data) public onlyRole(OPERATOR_ROLE) whenNotPaused nonReentrant {
        require(from != address(0), "OperatorControlContract: from address cannot be zero");
        require(to != address(0), "OperatorControlContract: to address cannot be zero");
        require(amount > 0, "OperatorControlContract: amount must be greater than zero");
        
        _send(from, to, amount, data, "", true);
        emit OperatorExecuted(msg.sender, from, to, amount, data);
    }

    /// @notice Add a new operator with the OPERATOR_ROLE
    /// @param operator Address to be granted the operator role
    function addOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
    }

    /// @notice Remove an existing operator with the OPERATOR_ROLE
    /// @param operator Address to be revoked the operator role
    function removeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
    }

    /// @notice Pause the contract, preventing all token transfers
    /// @dev Only accounts with the PAUSER_ROLE can pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing token transfers
    /// @dev Only accounts with the PAUSER_ROLE can unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Override the _beforeTokenTransfer function to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Check if an address has the OPERATOR_ROLE
    /// @param operator Address to check for the operator role
    /// @return true if the address has the operator role, false otherwise
    function isOperator(address operator) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, operator);
    }
}
```

### **Key Functionalities**:

1. **Operator-Controlled Transactions**:
   - Authorized operators with the `OPERATOR_ROLE` can execute transactions on behalf of token holders using the `operatorExecute` function.
   - Emits an `OperatorExecuted` event when an operator performs a transaction.

2. **Operator Management**:
   - Admin accounts can add and remove operators using the `addOperator` and `removeOperator` functions.

3. **Pause and Unpause**:
   - Accounts with the `PAUSER_ROLE` can pause or unpause the contract, preventing all token transfers during the pause period.

4. **Security and Compliance**:
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

       const OperatorControlContract = await ethers.getContractFactory("OperatorControlContract");
       const token = await OperatorControlContract.deploy(
           "OperatorControlToken", // Token name
           "OCT", // Token symbol
           [] // Default operators
       );

       console.log("OperatorControlContract deployed to:", token.address);
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
   npx hardhat verify --network mainnet <deployed_contract_address> "OperatorControlToken" "OCT" []
   ```

### **Further Customization**:

1. **KYC/AML Compliance**: 
   Integrate with a third-party KYC/AML service to restrict operator actions and ensure only verified accounts can perform certain actions.
   
2. **Operator Limitations**:
   Implement additional restrictions on operators, such as limiting the number of tokens they can operate on or the frequency of their actions.

3. **Governance Integration**:
   Include on-chain governance to allow token holders to vote on operator assignments and other key decisions.

4. **Multi-Network Deployment**:
   Deploy the contract on multiple networks such as Ethereum, BSC, or Layer-2 solutions like Polygon or Arbitrum.

This contract provides a robust foundation for an operator-controlled security token using the ERC777 standard. It should be rigorously tested and audited before being deployed in a production environment.