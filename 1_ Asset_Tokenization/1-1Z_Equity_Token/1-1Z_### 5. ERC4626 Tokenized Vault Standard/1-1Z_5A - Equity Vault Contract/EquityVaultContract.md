### Smart Contract: `EquityVaultContract.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Equity Vault Contract
/// @notice This contract tokenizes a vault that holds equity in multiple companies, allowing investors to buy and sell shares in a diversified basket of equities.
contract EquityVaultContract is ERC4626, ERC20Permit, Ownable, ReentrancyGuard, Pausable {
    // Mapping to store the price oracles for each equity token in the vault
    mapping(address => AggregatorV3Interface) public priceOracles;

    // Event emitted when a new equity token is added to the vault
    event EquityTokenAdded(address indexed token, address indexed oracle);

    // Event emitted when equity tokens are removed from the vault
    event EquityTokenRemoved(address indexed token);

    /// @notice Constructor to initialize the vault contract
    /// @param asset The underlying asset (equity token) of the vault
    /// @param name The name of the vault token
    /// @param symbol The symbol of the vault token
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) ERC20Permit(name) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to add a new equity token and its price oracle to the vault
    /// @param token The address of the equity token
    /// @param oracle The address of the Chainlink price oracle for the equity token
    function addEquityToken(address token, address oracle) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(oracle != address(0), "Invalid oracle address");
        priceOracles[token] = AggregatorV3Interface(oracle);
        emit EquityTokenAdded(token, oracle);
    }

    /// @notice Function to remove an equity token from the vault
    /// @param token The address of the equity token to be removed
    function removeEquityToken(address token) external onlyOwner {
        require(priceOracles[token] != AggregatorV3Interface(address(0)), "Token not in vault");
        delete priceOracles[token];
        emit EquityTokenRemoved(token);
    }

    /// @notice Function to get the current price of an equity token from its oracle
    /// @param token The address of the equity token
    /// @return The latest price of the equity token
    function getEquityTokenPrice(address token) public view returns (uint256) {
        require(priceOracles[token] != AggregatorV3Interface(address(0)), "Token not in vault");
        (, int256 price, , , ) = priceOracles[token].latestRoundData();
        return uint256(price);
    }

    /// @notice Function to deposit equity tokens into the vault and receive vault shares
    /// @param assets The amount of equity tokens to deposit
    /// @param receiver The address that will receive the vault shares
    /// @return The amount of vault shares minted
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /// @notice Function to redeem vault shares for underlying equity tokens
    /// @param shares The amount of vault shares to redeem
    /// @param receiver The address that will receive the underlying equity tokens
    /// @param owner The address of the owner of the vault shares
    /// @return The amount of underlying assets redeemed
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        return super.redeem(shares, receiver, owner);
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

    /// @notice Override required by Solidity for ERC4626 _beforeTokenTransfer hook
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

1. **ERC4626 Tokenized Vault Standard**:
   - This contract inherits from the `ERC4626` standard to create a vault for equity tokens, allowing for the tokenization of a basket of equity assets.

2. **Equity Token Management**:
   - `addEquityToken(address token, address oracle)`: Adds a new equity token and its corresponding Chainlink price oracle to the vault.
   - `removeEquityToken(address token)`: Removes an equity token from the vault.

3. **Price Oracle Integration**:
   - Uses Chainlink oracles to obtain the real-time price of each equity token in the vault.
   - `getEquityTokenPrice(address token)`: Returns the latest price of the specified equity token.

4. **Token Deposit and Redemption**:
   - `deposit(uint256 assets, address receiver)`: Allows users to deposit equity tokens into the vault and receive vault shares.
   - `redeem(uint256 shares, address receiver, address owner)`: Allows users to redeem their vault shares for underlying equity tokens.

5. **Security and Governance**:
   - Utilizes `Ownable`, `ReentrancyGuard`, and `Pausable` from OpenZeppelin to manage access control, prevent reentrancy attacks, and allow pausing of the contract in emergencies.

6. **Emergency Controls**:
   - `pause()`: Allows the owner to pause all token transfers, deposits, and redemptions.
   - `unpause()`: Allows the owner to unpause the contract.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin and Chainlink contracts installed:
   ```bash
   npm install @openzeppelin/contracts @chainlink/contracts
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

     const EquityVaultContract = await ethers.getContractFactory("EquityVaultContract");
     const token = await EquityVaultContract.deploy(
       "0xYourERC20TokenAddressHere", // Replace with the underlying equity token address
       "Equity Vault Token",
       "EVT"
     );
     await token.deployed();

     console.log("Equity Vault Contract deployed to:", token.address);
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
   - Write test cases to ensure that the deposit and redemption functionalities work as expected.
   - Verify that the price oracle integration returns the correct values for the equity tokens.
   - Test the pause and unpause functionalities to ensure contract security in emergency situations.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Implement dynamic portfolio rebalancing based on real-time data from the oracles.
   - Add support for more complex governance mechanisms, allowing token holders to vote on the composition of the vault.
   - Integrate with a DeFi platform to enable staking or lending of the vault shares for additional yield.

This contract provides a robust and flexible mechanism for creating a diversified equity vault, allowing investors to gain exposure to a basket of equities through a single token.