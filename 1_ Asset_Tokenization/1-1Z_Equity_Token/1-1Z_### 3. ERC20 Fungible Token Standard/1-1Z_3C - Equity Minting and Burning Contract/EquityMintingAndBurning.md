### Smart Contract: `EquityMintingAndBurning.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Minting and Burning Contract
/// @notice This contract allows companies to mint new equity tokens when issuing more shares or burn tokens during buybacks or capital reduction events, ensuring the correct representation of outstanding shares.
contract EquityMintingAndBurning is ERC20, Ownable, ReentrancyGuard, Pausable {
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Mints new tokens to the specified address
    /// @param to The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Burns tokens from the specified address
    /// @param from The address from which to burn the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /// @notice Allows the contract owner to pause all minting and burning operations
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause all minting and burning operations
    function unpause() external onlyOwner {
        _unpause();
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

    /// @notice Override ERC20 _beforeTokenTransfer to enforce pausing
    /// @dev This function is called before any transfer of tokens. This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **Minting and Burning**:
   - `mint(address to, uint256 amount)`: Allows the owner to mint new tokens to a specified address.
   - `burn(address from, uint256 amount)`: Allows the owner to burn tokens from a specified address.

2. **Pausing**:
   - `pause()`: Pauses all minting and burning operations.
   - `unpause()`: Unpauses all minting and burning operations.
   - The contract uses the `Pausable` modifier to allow pausing and unpausing of the minting and burning functions.

3. **Emergency Withdrawals**:
   - `emergencyWithdrawETH()`: Allows the owner to withdraw any ETH mistakenly sent to the contract.
   - `emergencyWithdrawERC20(address token, uint256 amount)`: Allows the owner to withdraw any ERC20 tokens mistakenly sent to the contract.

4. **Modifiers and Checks**:
   - The `onlyOwner` modifier is used for minting, burning, pausing, and emergency withdrawal functions to ensure only the contract owner can perform these actions.
   - The `whenNotPaused` modifier ensures that no minting or burning actions can be taken while the contract is paused.
   - The `nonReentrant` modifier is used to prevent reentrancy attacks in the emergency withdrawal functions.

5. **Fallback Function**:
   - The `receive()` function allows the contract to accept ETH deposits.

6. **Compliance**:
   - Complies with the ERC20 standard using OpenZeppelin's `ERC20` implementation.
   - Utilizes OpenZeppelin’s `Ownable`, `ReentrancyGuard`, and `Pausable` contracts for secure and robust functionality.

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

     const EquityMintingAndBurning = await ethers.getContractFactory("EquityMintingAndBurning");
     const token = await EquityMintingAndBurning.deploy("Equity Token", "EQT");
     await token.deployed();

     console.log("Equity Minting and Burning Contract deployed to:", token.address);
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
   - Write test cases to ensure that the minting and burning functionalities work as expected, and that only the owner can perform these actions.
   - Conduct thorough testing for edge cases such as burning more tokens than the balance, and unauthorized minting.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Implement governance features to allow token holders to vote on minting or burning decisions.
   - Integrate compliance modules to automatically verify that only authorized addresses can receive newly minted tokens.
   - Consider adding functionality to manage vesting schedules for minted tokens.

This contract provides a robust framework for companies to manage their equity tokens by minting and burning tokens as needed, while maintaining compliance and security.