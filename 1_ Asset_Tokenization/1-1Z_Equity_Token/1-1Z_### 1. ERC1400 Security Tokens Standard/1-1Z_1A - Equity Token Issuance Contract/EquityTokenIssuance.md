### Smart Contract: `EquityTokenIssuance.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Equity Token Issuance Contract
/// @notice This contract issues, manages, and governs equity tokens representing shares in a company.
contract EquityTokenIssuance is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Token interface for ERC20 compliance
    IERC20 public equityToken;

    // Minimum investment amount
    uint256 public minimumInvestment;

    // Maximum investment amount
    uint256 public maximumInvestment;

    // Total tokens available for sale
    uint256 public totalTokensForSale;

    // Price per token in wei
    uint256 public tokenPrice;

    // Mapping of investors to their allocated tokens
    mapping(address => uint256) public investorAllocations;

    // Set of investors who have invested
    EnumerableSet.AddressSet private investors;

    // Event emitted when an investment is made
    event Invested(address indexed investor, uint256 amount, uint256 tokenAmount);

    // Event emitted when tokens are claimed
    event TokensClaimed(address indexed investor, uint256 tokenAmount);

    // Event emitted when funds are withdrawn
    event FundsWithdrawn(address indexed admin, uint256 amount);

    // Modifier to check if the caller is an investor
    modifier onlyInvestor() {
        require(investorAllocations[msg.sender] > 0, "Caller is not an investor");
        _;
    }

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC20 token representing the equity
    /// @param _minimumInvestment Minimum amount of tokens required to invest
    /// @param _maximumInvestment Maximum amount of tokens an individual can invest
    /// @param _totalTokensForSale Total number of tokens available for sale
    /// @param _tokenPrice Price per token in wei
    constructor(
        IERC20 _equityToken,
        uint256 _minimumInvestment,
        uint256 _maximumInvestment,
        uint256 _totalTokensForSale,
        uint256 _tokenPrice
    ) {
        equityToken = _equityToken;
        minimumInvestment = _minimumInvestment;
        maximumInvestment = _maximumInvestment;
        totalTokensForSale = _totalTokensForSale;
        tokenPrice = _tokenPrice;
    }

    /// @notice Invest in the equity tokens
    /// @dev Emits an `Invested` event on success
    function invest() external payable whenNotPaused nonReentrant {
        uint256 weiAmount = msg.value;
        require(weiAmount >= minimumInvestment, "Investment amount is below minimum");
        require(weiAmount <= maximumInvestment, "Investment amount is above maximum");
        
        uint256 tokenAmount = weiAmount.div(tokenPrice);
        require(totalTokensForSale >= tokenAmount, "Not enough tokens available for sale");

        totalTokensForSale = totalTokensForSale.sub(tokenAmount);
        investorAllocations[msg.sender] = investorAllocations[msg.sender].add(tokenAmount);

        investors.add(msg.sender);

        emit Invested(msg.sender, weiAmount, tokenAmount);
    }

    /// @notice Claim allocated tokens after the sale
    /// @dev Only callable by the investor
    function claimTokens() external onlyInvestor whenNotPaused nonReentrant {
        uint256 tokenAmount = investorAllocations[msg.sender];
        require(tokenAmount > 0, "No tokens to claim");

        investorAllocations[msg.sender] = 0;
        equityToken.transfer(msg.sender, tokenAmount);

        emit TokensClaimed(msg.sender, tokenAmount);
    }

    /// @notice Withdraw invested funds
    /// @dev Only callable by the contract owner
    function withdrawFunds() external onlyOwner whenNotPaused nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        Address.sendValue(payable(owner()), contractBalance);

        emit FundsWithdrawn(owner(), contractBalance);
    }

    /// @notice Pause the contract
    /// @dev Only callable by the contract owner
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by the contract owner
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get the total number of investors
    /// @return uint256 Number of investors
    function getInvestorCount() external view returns (uint256) {
        return investors.length();
    }

    /// @notice Check if an address is an investor
    /// @param investor Address to check
    /// @return bool True if the address is an investor, false otherwise
    function isInvestor(address investor) external view returns (bool) {
        return investors.contains(investor);
    }

    /// @notice Get the allocated tokens for an investor
    /// @param investor Address of the investor
    /// @return uint256 Amount of allocated tokens
    function getAllocation(address investor) external view returns (uint256) {
        return investorAllocations[investor];
    }

    /// @notice Set a new minimum investment amount
    /// @param newMinimumInvestment New minimum investment amount in wei
    function setMinimumInvestment(uint256 newMinimumInvestment) external onlyOwner {
        minimumInvestment = newMinimumInvestment;
    }

    /// @notice Set a new maximum investment amount
    /// @param newMaximumInvestment New maximum investment amount in wei
    function setMaximumInvestment(uint256 newMaximumInvestment) external onlyOwner {
        maximumInvestment = newMaximumInvestment;
    }

    /// @notice Set a new token price
    /// @param newTokenPrice New token price in wei
    function setTokenPrice(uint256 newTokenPrice) external onlyOwner {
        tokenPrice = newTokenPrice;
    }
}
```

### Key Features of the Contract:

1. **Token Issuance and Distribution**:
   - Investors can purchase equity tokens by sending Ether to the contract.
   - The token amount is calculated based on the Ether sent and the set token price.
   - Investors can claim their allocated tokens after the investment round.

2. **Investment Limits**:
   - Minimum and maximum investment amounts are enforced to ensure compliance with investment policies.
   - These limits can be modified by the contract owner.

3. **Funds Management**:
   - Collected funds can be withdrawn by the contract owner to a specified address.
   - The `withdrawFunds` function allows for secure and transparent fund management.

4. **Pausable and Secure**:
   - The contract can be paused and unpaused by the owner using OpenZeppelin's `Pausable` contract.
   - The `nonReentrant` modifier ensures protection against reentrancy attacks during key operations.

5. **Investor Management**:
   - The contract tracks investor addresses and their allocated token amounts.
   - Investors can query their allocations and the total number of investors at any time.

6. **Modifiable Parameters**:
   - The owner can update the minimum investment, maximum investment, and token price parameters as needed.

7. **Event Logging**:
   - Events are emitted for key actions like investments, token claims, and fund withdrawals, ensuring transparency.

### Deployment Instructions:

1. **Install Dependencies**:
   Make sure OpenZeppelin contracts are installed:
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

     const EquityToken = await ethers.getContractFactory("EquityToken");
     const equityToken = await EquityToken.deploy();
     await equityToken.deployed();

     console.log("Equity Token deployed to:", equityToken.address);

     const EquityTokenIssuance = await ethers.getContractFactory("EquityTokenIssuance");
     const equityTokenIssuance = await EquityTokenIssuance.deploy(
       equityToken.address, // Address of the equity token contract
       ethers.utils.parseEther("0.1"), // Minimum investment in wei
       ethers.utils.parseEther("10"), // Maximum investment in wei
       ethers.utils.parseEther("1000"), // Total tokens for sale
       ethers.utils.parseEther("0.01") // Token price in wei
     );
     await equityTokenIssuance.deployed();

     console.log("Equity Token Issuance Contract deployed to:", equityTokenIssuance.address);
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
   - Write unit tests to verify core functionalities such as investments, claiming tokens, and withdrawing funds.


   - Perform a security audit to ensure compliance and secure operations.

6. **API Documentation**:
   - Document all public functions, events, and modifiers for developers and integrators.

### Next Steps:

- **Integration with Governance Contracts**: Implement on-chain governance using ERC-1400 features for managing shareholder voting and decisions.
- **KYC/AML Integration**: Incorporate compliance checks to ensure only verified and accredited investors can participate.
- **Enhanced Dividend Distribution**: Develop functionalities for distributing dividends to token holders based on their holdings.

This contract provides a secure and modular solution for issuing and managing equity tokens, enabling compliant digital asset issuance for companies looking to tokenize their shares.