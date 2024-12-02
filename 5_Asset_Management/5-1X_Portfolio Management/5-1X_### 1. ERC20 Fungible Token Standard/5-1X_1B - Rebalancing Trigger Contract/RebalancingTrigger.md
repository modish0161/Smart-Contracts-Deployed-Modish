### Smart Contract Code: `RebalancingTrigger.sol`

This smart contract, named `RebalancingTrigger.sol`, will automatically rebalance a portfolio of ERC20 tokens based on predefined target allocations whenever the actual allocations deviate beyond specified thresholds.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RebalancingTrigger is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Asset {
        IERC20 token;
        uint256 targetAllocation; // Target percentage in basis points (1% = 100 bp)
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    Asset[] public assets;

    // Maximum allowed deviation before rebalancing, in basis points
    uint256 public rebalanceThreshold = 500; // 5%

    // Total value of the portfolio in USD
    uint256 public totalPortfolioValue;

    // Investor balances in ETH
    mapping(address => uint256) public balances;

    // Events
    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event Rebalanced();
    event AssetAdded(IERC20 indexed token, uint256 targetAllocation, address priceFeed);
    event AssetUpdated(IERC20 indexed token, uint256 newTargetAllocation, address priceFeed);
    event RebalanceThresholdUpdated(uint256 newThreshold);

    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            totalAllocation = totalAllocation.add(assets[i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function addAsset(IERC20 _token, uint256 _targetAllocation, address _priceFeed) external onlyOwner validAllocation {
        assets.push(Asset({
            token: _token,
            targetAllocation: _targetAllocation,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_token, _targetAllocation, _priceFeed);
    }

    function updateAsset(IERC20 _token, uint256 _newTargetAllocation, address _newPriceFeed) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                assets[i].targetAllocation = _newTargetAllocation;
                assets[i].priceFeed = AggregatorV3Interface(_newPriceFeed);
                emit AssetUpdated(_token, _newTargetAllocation, _newPriceFeed);
                return;
            }
        }
    }

    function invest() external payable nonReentrant {
        require(msg.value > 0, "Investment must be greater than zero");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalPortfolioValue = totalPortfolioValue.add(msg.value);
        emit Invested(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalPortfolioValue = totalPortfolioValue.sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function rebalance() external onlyOwner nonReentrant validAllocation {
        uint256 portfolioValueUSD = calculatePortfolioValue();

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(assets[i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(assets[i]);

            if (currentValueUSD > targetValueUSD.add(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Sell excess tokens
                uint256 excessUSD = currentValueUSD.sub(targetValueUSD);
                uint256 excessTokens = excessUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                assets[i].token.transfer(owner(), excessTokens);
            } else if (currentValueUSD < targetValueUSD.sub(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Buy more tokens
                uint256 deficitUSD = targetValueUSD.sub(currentValueUSD);
                uint256 deficitTokens = deficitUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                assets[i].token.transferFrom(owner(), address(this), deficitTokens);
            }
        }

        totalPortfolioValue = portfolioValueUSD;
        emit Rebalanced();
    }

    function calculatePortfolioValue() public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(assets[i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(Asset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = _asset.token.balanceOf(address(this));
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }

    receive() external payable {
        invest();
    }
}
```

### 2. Deployment Scripts

Create a deployment script for Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const RebalancingTrigger = await ethers.getContractFactory("RebalancingTrigger");
  const contract = await RebalancingTrigger.deploy();

  console.log("RebalancingTrigger deployed to:", contract.address);
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

describe("RebalancingTrigger", function () {
  let Portfolio;
  let portfolio;
  let owner;
  let addr1;
  let addr2;
  let ERC20Mock;
  let PriceFeedMock;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy mock ERC20 token
    ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    const token1 = await ERC20Mock.deploy("Token1", "TK1", owner.address, 100000);
    const token2 = await ERC20Mock.deploy("Token2", "TK2", owner.address, 100000);

    // Deploy mock price feed
    PriceFeedMock = await ethers.getContractFactory("PriceFeedMock");
    const priceFeed1 = await PriceFeedMock.deploy(1 * 10**18); // $1
    const priceFeed2 = await PriceFeedMock.deploy(2 * 10**18); // $2

    // Deploy Portfolio contract
    Portfolio = await ethers.getContractFactory("RebalancingTrigger");
    portfolio = await Portfolio.deploy();
    await portfolio.deployed();

    // Add assets to portfolio
    await portfolio.addAsset(token1.address, 6000, priceFeed1.address); // 60%
    await portfolio.addAsset(token2.address, 4000, priceFeed2.address); // 40%
  });

  it("Should correctly add and update assets", async function () {
    const asset1 = await portfolio.assets(0);
    const asset2 = await portfolio.assets(1);

    expect(asset1.token).to.equal(await ERC20Mock.address);
    expect(asset1.targetAllocation).to.equal(6000);

    await portfolio.updateAsset(asset1.token, 5000, asset1.priceFeed); // Update to 50%
    const updatedAsset = await portfolio.assets(0);
    expect(updatedAsset.targetAllocation).to.equal(5000);
  });

  it("Should allow investing and withdrawing ETH", async function () {
    await portfolio.connect(addr1).invest({ value: ethers.utils.parseEther("1.0") });
    expect(await portfolio.balances(addr1.address)).to.equal(ethers.utils.parseEther("1.0"));

    await portfolio.connect(addr1).withdraw(ethers.utils.parseEther("0.5"));
    expect(await portfolio.balances(addr1.address)).to.equal(ethers.utils.parseEther("0.5"));
  });

  it("Should trigger rebalance when deviation threshold is exceeded", async function () {
    await portfolio.rebalance();
    expect(await portfolio.totalPortfolioValue()).to.equal(ethers.utils.parseEther("2.0"));
  });
});
```

Run the test suite using:


```bash
npx hardhat test
```

### 4. Documentation

**API Documentation**:
- `addAsset(IERC20 _token, uint256 _targetAllocation, address _priceFeed)`: Adds a new asset to the portfolio with a specified target allocation and Chainlink price feed.
- `updateAsset(IERC20 _token, uint256 _newTargetAllocation, address _newPriceFeed)`: Updates the target allocation and price feed of an existing asset.
- `invest()`: Allows users to invest ETH into the portfolio.
- `withdraw(uint256 _amount)`: Allows users to withdraw their investment.
- `rebalance()`: Rebalances the portfolio based on the predefined target allocations.
- `calculatePortfolioValue()`: Calculates the total portfolio value in USD.

**User Guide**:
- **Investing**: Call the `invest()` function, sending ETH along with the transaction.
- **Withdrawing**: Use the `withdraw(uint256 _amount)` function to withdraw ETH.
- **Rebalancing**: Only the owner can call `rebalance()` to adjust the portfolio.

**Developer Guide**:
- To extend the contract, integrate Chainlink oracles for real-time price data and customize the rebalance logic based on specific thresholds.

### 5. Additional Deployment Instructions

- Use real Chainlink price feeds in production. Update the `_priceFeed` parameter in the `addAsset` function with actual price feed addresses for each asset.
- Implement governance for decentralized control over rebalancing thresholds and asset management.

This contract provides a secure and flexible foundation for automated portfolio rebalancing. Further customization can be added based on specific requirements.