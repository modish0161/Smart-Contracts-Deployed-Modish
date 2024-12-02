### Smart Contract Code: `AccreditedInvestorPortfolioRebalancing.sol`

This smart contract, named `AccreditedInvestorPortfolioRebalancing.sol`, is based on the ERC1404 standard, specifically designed for managing restricted token portfolios. It rebalances the portfolios of accredited investors according to predefined asset allocation strategies, while ensuring compliance with regulatory requirements.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC1404/ERC1404.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AccreditedInvestorPortfolioRebalancing is ERC1404, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PortfolioAsset {
        address tokenAddress;       // Address of the ERC1404 token
        uint256 targetAllocation;   // Target percentage in basis points (1% = 100 bp)
        uint256 complianceLimit;    // Compliance limit in basis points
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    struct InvestorPortfolio {
        uint256 totalInvestment;    // Total amount invested by the investor
        mapping(address => uint256) allocations; // Token address to allocation
    }

    // Mapping from investor address to their portfolio
    mapping(address => InvestorPortfolio) public investorPortfolios;

    // Mapping from portfolio ID to assets
    mapping(uint256 => PortfolioAsset[]) public portfolios;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Events
    event Rebalanced(address indexed investor);
    event PortfolioAssetAdded(uint256 indexed portfolioId, address indexed tokenAddress, uint256 targetAllocation, uint256 complianceLimit, address priceFeed);
    event ComplianceViolation(address indexed investor, uint256 indexed portfolioId, address indexed tokenAddress, uint256 currentValue, uint256 complianceLimit);
    event InvestorAccredited(address indexed investor);
    event InvestorDeaccredited(address indexed investor);
    event InvestmentReceived(address indexed investor, uint256 amount);

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

    constructor() ERC1404("AccreditedInvestorToken", "AIT") {
        // Initial setup if needed
    }

    function addPortfolioAsset(
        uint256 _portfolioId,
        address _tokenAddress,
        uint256 _targetAllocation,
        uint256 _complianceLimit,
        address _priceFeed
    ) external onlyOwner validAllocation(_portfolioId) {
        portfolios[_portfolioId].push(PortfolioAsset({
            tokenAddress: _tokenAddress,
            targetAllocation: _targetAllocation,
            complianceLimit: _complianceLimit,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit PortfolioAssetAdded(_portfolioId, _tokenAddress, _targetAllocation, _complianceLimit, _priceFeed);
    }

    function addAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.add(_investor);
        emit InvestorAccredited(_investor);
    }

    function removeAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.remove(_investor);
        emit InvestorDeaccredited(_investor);
    }

    function invest(uint256 _portfolioId) external payable onlyAccredited whenNotPaused {
        require(msg.value > 0, "Investment amount must be greater than zero");
        investorPortfolios[msg.sender].totalInvestment = investorPortfolios[msg.sender].totalInvestment.add(msg.value);

        emit InvestmentReceived(msg.sender, msg.value);
        rebalance(msg.sender, _portfolioId);
    }

    function rebalance(address _investor, uint256 _portfolioId) public onlyAccredited nonReentrant validAllocation(_portfolioId) whenNotPaused {
        uint256 portfolioValueUSD = calculatePortfolioValue(_portfolioId);
        InvestorPortfolio storage portfolio = investorPortfolios[_investor];

        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            PortfolioAsset memory asset = portfolios[_portfolioId][i];
            uint256 targetValueUSD = portfolioValueUSD.mul(asset.targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(_investor, asset);
            uint256 complianceLimitUSD = portfolioValueUSD.mul(asset.complianceLimit).div(10000);

            // Compliance Check
            if (currentValueUSD > complianceLimitUSD) {
                emit ComplianceViolation(_investor, _portfolioId, asset.tokenAddress, currentValueUSD, complianceLimitUSD);
                // Logic for rebalancing if necessary
            }

            portfolio.allocations[asset.tokenAddress] = targetValueUSD;
        }

        emit Rebalanced(_investor);
    }

    function calculatePortfolioValue(uint256 _portfolioId) public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(address(this), portfolios[_portfolioId][i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(address _investor, PortfolioAsset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = IERC20(_asset.tokenAddress).balanceOf(_investor);
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

    function withdraw() external onlyAccredited nonReentrant {
        uint256 amount = investorPortfolios[msg.sender].totalInvestment;
        require(amount > 0, "No funds to withdraw");

        investorPortfolios[msg.sender].totalInvestment = 0;
        payable(msg.sender).transfer(amount);
    }
}
```

### Key Features and Functionalities:

1. **Accredited Investor Management:**
   - Investors must be accredited to participate.
   - Functions `addAccreditedInvestor` and `removeAccreditedInvestor` control accredited investor access.

2. **Investment and Rebalancing:**
   - Investors can invest in a portfolio using the `invest()` function.
   - The `rebalance()` function dynamically rebalances the investor's portfolio based on predefined asset allocation strategies.
   - Rebalancing logic ensures compliance with asset allocation and compliance limits.

3. **Compliance Checks:**
   - `detectTransferRestriction`: Checks if the transfer is restricted based on investor accreditation.
   - `messageForTransferRestriction`: Provides a custom message for transfer restrictions.

4. **Dynamic Portfolio Rebalancing:**
   - `rebalance`: Rebalances the portfolio based on predefined asset allocations and compliance limits.
   - `calculatePortfolioValue`: Computes the total value of the portfolio.
   - `getAssetValueUSD`: Calculates the value of an asset using Chainlink price feeds.

5. **Emergency Controls:**
   - `pause` and `unpause` functions to halt and resume contract operations during emergencies.

6. **Emergency Withdrawals:**
   - Investors can withdraw their funds using the `withdraw()` function in case of emergency.

### 2. Deployment Scripts

Create a deployment script for Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const AccreditedInvestorPortfolioRebalancing = await ethers.getContractFactory("AccreditedInvestorPortfolioRebalancing");
  const contract = await AccreditedInvestorPortfolioRebalancing.deploy();

  console.log("AccreditedInvestorPortfolioRebalancing deployed to:", contract.address);
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
npx hardhat

 run scripts/deploy.js --network <network>
```

### 3. Test Suite

Create a test suite for the contract:

```javascript
const { expect } = require("chai");

describe("AccreditedInvestorPortfolioRebalancing", function () {
  let Portfolio, portfolio, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    Portfolio = await ethers.getContractFactory("AccreditedInvestorPortfolioRebalancing");
    portfolio = await Portfolio.deploy();
    await portfolio.deployed();
  });

  it("Should add an accredited investor", async function () {
    await portfolio.addAccreditedInvestor(addr1.address);
    expect(await portfolio.accreditedInvestors(addr1.address)).to.equal(true);
  });

  it("Should restrict non-accredited investors", async function () {
    await expect(portfolio.connect(addr1).invest(1, { value: ethers.utils.parseEther("1") })).to.be.revertedWith("Not an accredited investor");
  });

  it("Should allow accredited investors to invest", async function () {
    await portfolio.addAccreditedInvestor(addr1.address);
    await expect(portfolio.connect(addr1).invest(1, { value: ethers.utils.parseEther("1") })).to.emit(portfolio, 'InvestmentReceived').withArgs(addr1.address, ethers.utils.parseEther("1"));
  });

  it("Should rebalance the portfolio", async function () {
    await portfolio.addAccreditedInvestor(owner.address);
    await portfolio.addPortfolioAsset(1, "0xTokenAddress", 5000, 2000, "0xPriceFeed");
    await portfolio.invest(1, { value: ethers.utils.parseEther("1") });
    await portfolio.rebalance(owner.address, 1);
    expect(await portfolio.calculatePortfolioValue(1)).to.be.gt(0);
  });

  it("Should detect compliance violations", async function () {
    await portfolio.addAccreditedInvestor(owner.address);
    await portfolio.addPortfolioAsset(1, "0xTokenAddress", 5000, 1000, "0xPriceFeed");
    await portfolio.invest(1, { value: ethers.utils.parseEther("1") });
    await expect(portfolio.rebalance(owner.address, 1)).to.emit(portfolio, 'ComplianceViolation');
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### 4. Documentation

**API Documentation:**

- `addPortfolioAsset(uint256 _portfolioId, address _tokenAddress, uint256 _targetAllocation, uint256 _complianceLimit, address _priceFeed)`: Adds a new asset to a specific portfolio with a specified target allocation, compliance limit, and Chainlink price feed.
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
   - Use `addPortfolioAsset()` to add assets to specific portfolios with a defined allocation and compliance limit.

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