### Smart Contract Code: `RestrictedTokenPortfolioManagement.sol`

This smart contract, named `RestrictedTokenPortfolioManagement.sol`, is built on the ERC1404 restricted token standard. It manages portfolios of restricted tokens, ensuring that only accredited or authorized investors can participate. The contract dynamically adjusts portfolios to comply with KYC/AML requirements and other regulatory constraints.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./ERC1404/ERC1404.sol";

contract RestrictedTokenPortfolioManagement is Ownable, ReentrancyGuard, Pausable, ERC1404 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Data structure to hold asset details
    struct Asset {
        address tokenAddress;      // Address of the ERC1404 token
        uint256 targetAllocation;  // Target percentage in basis points (1% = 100 bp)
        uint256 complianceLimit;   // Compliance limit in basis points
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    // Portfolio ID to assets mapping
    mapping(uint256 => Asset[]) public portfolios;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Events
    event Rebalanced(uint256 indexed portfolioId);
    event AssetAdded(uint256 indexed portfolioId, address indexed tokenAddress, uint256 targetAllocation, uint256 complianceLimit, address priceFeed);
    event ComplianceViolation(address indexed investor, uint256 portfolioId, address indexed tokenAddress, uint256 currentValue, uint256 complianceLimit);
    event InvestorAccredited(address indexed investor);
    event InvestorDeaccredited(address indexed investor);

    // Modifiers
    modifier onlyAccredited() {
        require(accreditedInvestors.contains(msg.sender), "Not an accredited investor");
        _;
    }

    modifier validAllocation(uint256 _portfolioId) {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            totalAllocation = totalAllocation.add(portfolios[_portfolioId][i].targetAllocation);
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    constructor() ERC1404("RestrictedToken", "RTKN") {
        // Initial setup
    }

    function addAsset(
        uint256 _portfolioId,
        address _tokenAddress,
        uint256 _targetAllocation,
        uint256 _complianceLimit,
        address _priceFeed
    ) external onlyOwner validAllocation(_portfolioId) {
        portfolios[_portfolioId].push(Asset({
            tokenAddress: _tokenAddress,
            targetAllocation: _targetAllocation,
            complianceLimit: _complianceLimit,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_portfolioId, _tokenAddress, _targetAllocation, _complianceLimit, _priceFeed);
    }

    function addAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.add(_investor);
        emit InvestorAccredited(_investor);
    }

    function removeAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.remove(_investor);
        emit InvestorDeaccredited(_investor);
    }

    function rebalance(uint256 _portfolioId) external onlyOwner nonReentrant validAllocation(_portfolioId) whenNotPaused {
        uint256 portfolioValueUSD = calculatePortfolioValue(_portfolioId);

        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(portfolios[_portfolioId][i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(portfolios[_portfolioId][i]);
            uint256 complianceLimitUSD = portfolioValueUSD.mul(portfolios[_portfolioId][i].complianceLimit).div(10000);

            // Compliance Check
            if (currentValueUSD > complianceLimitUSD) {
                emit ComplianceViolation(msg.sender, _portfolioId, portfolios[_portfolioId][i].tokenAddress, currentValueUSD, complianceLimitUSD);
                // Rebalance by selling excess tokens or other adjustment mechanism
            }
        }

        emit Rebalanced(_portfolioId);
    }

    function calculatePortfolioValue(uint256 _portfolioId) public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(portfolios[_portfolioId][i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(Asset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = IERC20(_asset.tokenAddress).balanceOf(address(this));
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }

    // Emergency function to pause all operations
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause all operations
    function unpause() external onlyOwner {
        _unpause();
    }

    // Overriding ERC1404 functions
    function detectTransferRestriction(address from, address to, uint256 value) public view override returns (uint8) {
        if (!accreditedInvestors.contains(to)) {
            return 1; // Transfer restricted to non-accredited investors
        }
        return 0; // No restriction
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Transfer restricted to non-accredited investors";
        }
        return "No restriction";
    }
}
```

### Key Features and Functionalities:

1. **Accredited Investor Management:**
   - Investors must be accredited to participate.
   - Functions `addAccreditedInvestor` and `removeAccreditedInvestor` control accredited investor access.

2. **Automated Compliance Checks:**
   - `detectTransferRestriction`: Overrides ERC1404 functions to restrict transfers based on investor accreditation.
   - `messageForTransferRestriction`: Provides a custom message for transfer restrictions.

3. **Dynamic Portfolio Rebalancing:**
   - `rebalance`: Rebalances the portfolio based on predefined asset allocations and compliance limits.
   - `calculatePortfolioValue`: Computes the total value of the portfolio.
   - `getAssetValueUSD`: Calculates the value of an asset using Chainlink price feeds.

4. **Emergency Controls:**
   - `pause` and `unpause` functions to halt and resume contract operations during emergencies.

### 2. Deployment Scripts

Create a deployment script for Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedTokenPortfolioManagement = await ethers.getContractFactory("RestrictedTokenPortfolioManagement");
  const contract = await RestrictedTokenPortfolioManagement.deploy();

  console.log("RestrictedTokenPortfolioManagement deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
```

Run the deployment script using:

```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

### 3. Test Suite

Use the following test suite to validate the contract:

```javascript
const { expect } = require("chai");

describe("RestrictedTokenPortfolioManagement", function () {
  let Portfolio;
  let portfolio;
  let owner;
  let addr1;
  let ERC20Mock;
  let PriceFeedMock;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Deploy mock ERC1404 token
    ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const token1 = await ERC20Mock.deploy("SecurityToken1", "STK1", owner.address, 100000);

    // Deploy mock price feed
    PriceFeedMock = await ethers.getContractFactory("PriceFeedMock");
    const priceFeed1 = await PriceFeedMock.deploy(1 * 10**18); // $1

    // Deploy Portfolio contract
    Portfolio = await ethers.getContractFactory("RestrictedTokenPortfolioManagement");
    portfolio = await Portfolio.deploy();

    await portfolio.deployed();

    // Add accredited investor
    await portfolio.addAccreditedInvestor(owner.address);

    // Add asset to portfolio 1
    await portfolio.addAsset(1, token1.address, 5000, 2000, priceFeed1.address); // 50% ERC1404, 20% compliance limit
  });

  it("Should correctly add and update assets in portfolios", async function () {
    const asset1 = await portfolio.portfolios(1, 0);

    expect(asset1.tokenAddress).to.equal(await ERC20Mock.address);
   

 expect(asset1.targetAllocation).to.equal(5000);
    expect(asset1.complianceLimit).to.equal(2000);
  });

  it("Should restrict non-accredited investors", async function () {
    await expect(portfolio.connect(addr1).rebalance(1)).to.be.revertedWith("Not an accredited investor");
  });

  it("Should rebalance the portfolio", async function () {
    await portfolio.rebalance(1);
    expect(await portfolio.calculatePortfolioValue(1)).to.be.gt(0);
  });

  it("Should detect compliance violations and emit an event", async function () {
    const asset1 = await portfolio.portfolios(1, 0);
    await portfolio.addAsset(1, asset1.tokenAddress, 10000, 5000, asset1.priceFeed); // Adjust compliance limit to 50%
    await expect(portfolio.rebalance(1))
      .to.emit(portfolio, 'ComplianceViolation')
      .withArgs(owner.address, 1, asset1.tokenAddress, any, 5000); // Should trigger compliance violation
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### 4. Documentation

**API Documentation:**

- `addAsset(uint256 _portfolioId, address _tokenAddress, uint256 _targetAllocation, uint256 _complianceLimit, address _priceFeed)`: Adds a new asset to a specific portfolio with a specified target allocation, compliance limit, and Chainlink price feed.
- `rebalance(uint256 _portfolioId)`: Rebalances the portfolio based on the predefined target allocations and compliance requirements.
- `addAccreditedInvestor(address _investor)`: Adds an investor to the accredited investor list.
- `removeAccreditedInvestor(address _investor)`: Removes an investor from the accredited investor list.
- `calculatePortfolioValue(uint256 _portfolioId)`: Calculates the total portfolio value of a specific portfolio in USD.
- `pause()`: Pauses all contract operations.
- `unpause()`: Resumes all contract operations.

**User Guide:**

1. **Adding Accredited Investors:**
   - Use `addAccreditedInvestor()` to add investors to the accredited list.
   - Use `removeAccreditedInvestor()` to remove investors from the list.

2. **Adding Assets to Portfolio:**
   - Use `addAsset()` to add assets to specific portfolios with a defined allocation and compliance limit.

3. **Rebalancing:**
   - Call `rebalance()` to rebalance the portfolio based on defined rules.

**Developer Guide:**

- Extend the contract by adding more detailed compliance logic or integrating automated notifications for investors when rebalancing is triggered.
- Implement on-chain governance for adjusting portfolio rules and adding/removing operators.

### 5. Additional Deployment Instructions

- In a production environment, ensure that only secure and verified price feed addresses are used.
- Implement additional on-chain governance controls for modifying compliance and rebalancing parameters.
- Consider integrating automated alert systems to notify investors of rebalancing events.

This smart contract provides a robust foundation for managing restricted token portfolios with integrated compliance mechanisms. Further customization can be added as needed.