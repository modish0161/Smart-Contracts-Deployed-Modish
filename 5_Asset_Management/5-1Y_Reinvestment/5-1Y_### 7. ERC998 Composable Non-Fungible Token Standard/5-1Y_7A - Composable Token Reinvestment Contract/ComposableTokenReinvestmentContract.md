### Smart Contract: `ComposableTokenReinvestmentContract.sol`

This contract utilizes the ERC998 standard to support reinvestment in composable tokens, where reinvested profits can be allocated across multiple underlying assets. It ensures that profits generated by the parent token are reinvested into its component assets, optimizing the overall value of the composable token.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract ComposableTokenReinvestmentContract is Ownable, ReentrancyGuard, ERC998TopDown {
    using SafeMath for uint256;

    struct ChildAsset {
        address assetAddress;
        uint256 tokenId;
        uint256 percentage;
    }

    mapping(uint256 => ChildAsset[]) public tokenAssets; // Maps parent token to its child assets
    IERC20 public profitToken; // Token in which profits are paid
    IERC20 public assetToken;  // Token used for reinvestment

    event Reinvested(uint256 indexed parentTokenId, uint256 amount, address assetAddress, uint256 tokenId);
    event ChildAssetAdded(uint256 indexed parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage);

    constructor(string memory name, string memory symbol, address _profitToken, address _assetToken) ERC721(name, symbol) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_assetToken != address(0), "Invalid asset token address");
        profitToken = IERC20(_profitToken);
        assetToken = IERC20(_assetToken);
    }

    // Function to add child assets to a parent token
    function addChildAsset(uint256 parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage) external onlyOwner {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");
        require(assetAddress != address(0), "Invalid asset address");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        tokenAssets[parentTokenId].push(ChildAsset({
            assetAddress: assetAddress,
            tokenId: tokenId,
            percentage: percentage
        }));

        emit ChildAssetAdded(parentTokenId, assetAddress, tokenId, percentage);
    }

    // Function to reinvest profits into the underlying assets
    function reinvest(uint256 parentTokenId) external nonReentrant {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");

        uint256 profitAmount = profitToken.balanceOf(address(this));
        require(profitAmount > 0, "No profits to reinvest");

        // Reinvest into each child asset according to its percentage
        for (uint256 i = 0; i < tokenAssets[parentTokenId].length; i++) {
            ChildAsset memory child = tokenAssets[parentTokenId][i];
            uint256 reinvestAmount = profitAmount.mul(child.percentage).div(100);

            // Transfer reinvest amount to the child asset
            profitToken.transfer(child.assetAddress, reinvestAmount);
            emit Reinvested(parentTokenId, reinvestAmount, child.assetAddress, child.tokenId);
        }
    }

    // Function to deposit profits into the contract
    function depositProfits(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(profitToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    // Function to create a new parent composable token
    function mintComposableToken(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    // Function to withdraw profits from the contract
    function withdrawProfits(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= profitToken.balanceOf(address(this)), "Insufficient balance");
        profitToken.transfer(owner(), amount);
    }

    // Function to set profit and asset tokens
    function setTokens(address _profitToken, address _assetToken) external onlyOwner {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_assetToken != address(0), "Invalid asset token address");
        profitToken = IERC20(_profitToken);
        assetToken = IERC20(_assetToken);
    }
}
```

### Key Features and Functionalities:

1. **Composable Token Management**:
   - `addChildAsset()`: Adds child assets to a parent token, allowing profits to be reinvested according to the specified percentage allocation.
   - `mintComposableToken()`: Mints a new composable parent token that can hold underlying assets.

2. **Profit Reinvestment**:
   - `reinvest()`: Reinvests profits into the underlying child assets based on the specified percentages. Profits are distributed proportionally to the child assets of the parent token.

3. **Profit Management**:
   - `depositProfits()`: Allows depositing profits into the contract for reinvestment purposes.
   - `withdrawProfits()`: Enables the owner to withdraw accumulated profits from the contract.

4. **Administrative Functions**:
   - `setTokens()`: Sets or updates the profit and asset tokens used for reinvestment.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const profitToken = "0x123..."; // Replace with actual profit token address
  const assetToken = "0x456..."; // Replace with actual asset token address

  console.log("Deploying contracts with the account:", deployer.address);

  const ComposableTokenReinvestmentContract = await ethers.getContractFactory("ComposableTokenReinvestmentContract");
  const contract = await ComposableTokenReinvestmentContract.deploy("Composable Token Reinvestment", "CTR", profitToken, assetToken);

  console.log("ComposableTokenReinvestmentContract deployed to:", contract.address);
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
npx hardhat run scripts/deploy.js --network <network>
```

### Test Suite

Create a test suite for the contract:

```javascript
const { expect } = require("chai");

describe("ComposableTokenReinvestmentContract", function () {
  let ComposableTokenReinvestmentContract, contract, owner, addr1, profitToken, assetToken;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC20 profit and asset tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    profitToken = await ERC20Mock.deploy("Profit Token", "PTK", 18);
    assetToken = await ERC20Mock.deploy("Asset Token", "ATK", 18);

    ComposableTokenReinvestmentContract = await ethers.getContractFactory("ComposableTokenReinvestmentContract");
    contract = await ComposableTokenReinvestmentContract.deploy("Composable Token Reinvestment", "CTR", profitToken.address, assetToken.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing and approve
    await profitToken.mint(addr1.address, 1000);
    await profitToken.connect(addr1).approve(contract.address, 500);
  });

  it("Should mint a new composable token", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    expect(await contract.ownerOf(1)).to.equal(addr1.address);
  });

  it("Should allow adding child assets to a composable token", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    await contract.addChildAsset(1, assetToken.address, 1, 50);
    const childAssets = await contract.tokenAssets(1, 0);

    expect(childAssets.assetAddress).to.equal(assetToken.address);
    expect(childAssets.percentage).to.equal(50);
  });

  it("Should allow depositing profits", async function () {
    await contract.connect(addr1).depositProfits(500);
    expect(await profitToken.balanceOf(contract.address)).to.equal(500);
  });

  it("Should reinvest profits into child assets", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    await contract.addChildAsset(1, assetToken.address, 1, 100);

    await contract.connect(addr1).depositProfits(500);
    await contract.reinvest(1);

    // Check if profits were reinvested
    expect(await profitToken.balanceOf(assetToken.address)).to.equal(500);
  });

  it("Should allow withdrawing profits", async function () {
    await contract.connect(addr1).depositProfits(500);
    await contract.withdrawProfits(500);

    expect(await profitToken.balanceOf(owner.address)).to.equal(500);
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### Additional Customizations

1. **Dynamic Reinvestment Strategies**: Implement reinvestment strategies that dynamically adjust allocations based on real-time performance data.
2. **Governance Features**: Add on-chain governance for updating reinvestment strategies and asset allocation rules.
3. **Multi-Asset Reinvestment**: Support reinvestment into multiple asset classes, allowing users to diversify their compos

able token portfolios.

This contract facilitates automated reinvestment of profits into underlying assets, adhering to the ERC998 standard, enabling users to optimize the value of their composable tokens.