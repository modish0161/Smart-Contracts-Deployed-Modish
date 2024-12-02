### Smart Contract: `AdvancedEquityToken.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Advanced Equity Token Contract
/// @notice This contract issues equity tokens with enhanced functionality, allowing for features like authorized operators who can manage tokens on behalf of shareholders. This is useful in highly regulated industries or for larger enterprises.
contract AdvancedEquityToken is ERC777, Ownable, Pausable, ReentrancyGuard {
    // Mapping to track operators and their permissions
    mapping(address => bool) private _authorizedOperators;

    // Events
    event OperatorAuthorized(address indexed operator);
    event OperatorRevoked(address indexed operator);
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    /// @notice Constructor to initialize the equity token
    /// @param name The name of the equity token
    /// @param symbol The symbol of the equity token
    /// @param defaultOperators The initial list of default operators
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {}

    /// @notice Authorizes an operator to manage tokens on behalf of shareholders
    /// @param operator The address of the operator to be authorized
    function authorizeOperator(address operator) external onlyOwner {
        require(!_authorizedOperators[operator], "Operator already authorized");
        _authorizedOperators[operator] = true;
        emit OperatorAuthorized(operator);
    }

    /// @notice Revokes an operator's authorization
    /// @param operator The address of the operator to be revoked
    function revokeOperator(address operator) external onlyOwner {
        require(_authorizedOperators[operator], "Operator not authorized");
        _authorizedOperators[operator] = false;
        emit OperatorRevoked(operator);
    }

    /// @notice Checks if an address is an authorized operator
    /// @param operator The address to check
    /// @return bool indicating whether the address is an authorized operator
    function isAuthorizedOperator(address operator) public view returns (bool) {
        return _authorizedOperators[operator];
    }

    /// @notice Mints new equity tokens to a specified address
    /// @param to The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount, "", "");
        emit TokenMinted(to, amount);
    }

    /// @notice Burns equity tokens from a specified address
    /// @param from The address from which to burn the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount, "", "");
        emit TokenBurned(from, amount);
    }

    /// @notice Pauses all token transfers and operator actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers and operator actions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Override required by Solidity for ERC777 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Allows the owner to withdraw any ETH mistakenly sent to this contract
    function emergencyWithdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens mistakenly sent to this contract
    /// @param token The address of the ERC20 token
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(owner(), amount);
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}
}
```

### Key Features of the Contract:

1. **ERC777 Advanced Token Standard**:
   - Inherits from OpenZeppelin’s ERC777 contract to provide advanced features such as authorized operators.

2. **Operator Management**:
   - `authorizeOperator(address operator)`: Allows the owner to authorize an operator to manage tokens on behalf of shareholders.
   - `revokeOperator(address operator)`: Allows the owner to revoke an operator’s authorization.
   - `isAuthorizedOperator(address operator)`: Public function to check if an address is an authorized operator.

3. **Minting and Burning**:
   - `mint(address to, uint256 amount)`: Allows the owner to mint new tokens to a specified address.
   - `burn(address from, uint256 amount)`: Allows the owner to burn tokens from a specified address.

4. **Pausing Mechanism**:
   - `pause()`: Allows the owner to pause all token transfers and operator actions.
   - `unpause()`: Allows the owner to unpause all token transfers and operator actions.

5. **Emergency Withdrawals**:
   - `emergencyWithdrawETH()`: Allows the owner to withdraw ETH mistakenly sent to the contract.
   - `emergencyWithdrawERC20(address token, uint256 amount)`: Allows the owner to withdraw ERC20 tokens mistakenly sent to the contract.

6. **Fallback Function**:
   - `receive()`: Allows the contract to accept ETH deposits.

7. **Compliance and Security**:
   - Complies with ERC777 standard using OpenZeppelin’s ERC777 implementation.
   - Utilizes OpenZeppelin’s `Ownable`, `Pausable`, and `ReentrancyGuard` contracts for secure and robust functionality.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the contract using Hardhat or Truffle:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Example Hardhat deployment script:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const AdvancedEquityToken = await ethers.getContractFactory("AdvancedEquityToken");
     const token = await AdvancedEquityToken.deploy("Advanced Equity Token", "AET", []);
     await token.deployed();

     console.log("Advanced Equity Token Contract deployed to:", token.address);
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

5. **Testing and Auditing**:
   - Write test cases to ensure that the operator management functionalities work as expected.
   - Conduct thorough testing for edge cases such as unauthorized minting or burning of tokens.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Implement custom operator permissions for more granular control over token operations.
   - Integrate with oracles for dynamic operator validation and approval.
   - Add features such as dividend distribution and corporate governance voting.

This contract provides advanced functionalities for managing equity tokens in a highly regulated environment, allowing for greater control and flexibility over token operations and compliance management.