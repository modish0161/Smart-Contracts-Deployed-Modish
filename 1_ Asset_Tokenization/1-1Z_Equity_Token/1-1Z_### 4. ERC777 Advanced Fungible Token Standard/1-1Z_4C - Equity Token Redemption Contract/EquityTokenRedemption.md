### Smart Contract: `EquityTokenRedemption.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Token Redemption Contract
/// @notice This contract allows shareholders to redeem their equity tokens for company assets or funds, providing liquidity and exit strategies for investors in tokenized equity offerings.
contract EquityTokenRedemption is ERC777, Ownable, ReentrancyGuard, Pausable {
    // Mapping to store the token redemption value in Ether for each token holder
    mapping(address => uint256) public redemptionValue;

    // Event emitted when tokens are redeemed
    event TokensRedeemed(address indexed redeemer, uint256 amount, uint256 value);

    /// @notice Constructor to initialize the ERC777 token and contract settings
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param defaultOperators The initial list of default operators
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to set the redemption value for each token holder
    /// @param account The address of the token holder
    /// @param value The redemption value in Ether per token
    function setRedemptionValue(address account, uint256 value) external onlyOwner {
        redemptionValue[account] = value;
    }

    /// @notice Function to redeem tokens for Ether
    /// @param amount The amount of tokens to redeem
    function redeemTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        uint256 redemptionAmount = redemptionValue[msg.sender] * amount;
        require(address(this).balance >= redemptionAmount, "Insufficient contract balance");

        _burn(msg.sender, amount, "", "");
        payable(msg.sender).transfer(redemptionAmount);

        emit TokensRedeemed(msg.sender, amount, redemptionAmount);
    }

    /// @notice Function to withdraw Ether from the contract (for owner)
    /// @param amount The amount of Ether to withdraw
    function withdrawEther(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner()).transfer(amount);
    }

    /// @notice Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {}

    /// @notice Override required by Solidity for ERC777 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **ERC777 Advanced Token Standard**:
   - Inherits from OpenZeppelin’s ERC777 contract to leverage advanced features such as operator permissions and flexible token management.

2. **Redemption Mechanism**:
   - `setRedemptionValue(address account, uint256 value)`: Allows the owner to set a redemption value (in Ether) for each token holder.
   - `redeemTokens(uint256 amount)`: Allows token holders to redeem their tokens for the equivalent value in Ether. The redemption value is set per holder.

3. **Access Control and Security**:
   - Utilizes OpenZeppelin’s `Ownable`, `ReentrancyGuard`, and `Pausable` contracts to manage access control, prevent reentrancy attacks, and allow pausing of the contract in emergencies.

4. **Ether Management**:
   - `withdrawEther(uint256 amount)`: Allows the contract owner to withdraw Ether from the contract.
   - `receive() external payable`: Fallback function to allow the contract to receive Ether, which can be used for redemptions.

5. **Emergency Controls**:
   - `pause()`: Allows the owner to pause all token transfers and redemptions.
   - `unpause()`: Allows the owner to unpause the contract.

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

     const EquityTokenRedemption = await ethers.getContractFactory("EquityTokenRedemption");
     const token = await EquityTokenRedemption.deploy("Equity Redemption Token", "ERT", []);
     await token.deployed();

     console.log("Equity Token Redemption Contract deployed to:", token.address);
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
   - Write test cases to ensure that the redemption and Ether management functionalities work as expected.
   - Conduct thorough testing for edge cases such as insufficient Ether in the contract, unauthorized access attempts, and paused contract conditions.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Implement a dynamic redemption value mechanism based on real-time market data using Chainlink or other oracles.
   - Add a voting mechanism to allow shareholders to decide on the redemption rate or other corporate actions.
   - Integrate with a multi-signature wallet for enhanced security and approval of large redemptions.

This contract provides a secure and robust mechanism for shareholders to redeem their equity tokens for Ether, enabling liquidity and exit strategies for investors.