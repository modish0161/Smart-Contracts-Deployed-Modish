### Smart Contract: `MultiLayerReinvestmentContract.sol`

This smart contract uses the ERC998 standard to support reinvestment at multiple layers within a composable token structure. Profits are reinvested not only into the parent token but also into its underlying assets, enabling complex reinvestment strategies for bundled assets.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract MultiLayerReinvestmentContract is Ownable, ReentrancyGuard, ERC998TopDown {
    using SafeMath for uint256;

    struct LayerAsset {
        address assetAddress;
        uint256 tokenId;
        uint256 percentage; // Percentage of reinvestment to this asset
    }

    // Mapping from parent token ID to its layer assets
    mapping(uint256 => LayerAsset[]) public layerAssets;
    IERC20 public profitToken; // Token in which profits are distributed
    IERC20 public reinvestToken; // Token used for reinvestment

    event ProfitReinvested(uint256 indexed parentTokenId, uint256 amount, address assetAddress, uint256 tokenId);
    event LayerAssetAdded(uint256 indexed parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage);

    constructor(
        string memory name,
        string memory symbol,
        address _profitToken,
        address _reinvestToken
    ) ERC721(name, symbol) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_reinvestToken != address(0), "Invalid reinvest token address");
        profitToken = IERC20(_profitToken);
        reinvestToken = IERC20(_reinvestToken);
    }

    // Function to add a layer asset to a parent token
    function addLayerAsset(
        uint256 parentTokenId,
        address assetAddress,
        uint256 tokenId,
        uint256 percentage
    ) external onlyOwner {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");
        require(assetAddress != address(0), "Invalid asset address");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        layerAssets[parentTokenId].push(
            LayerAsset({
                assetAddress: assetAddress,
                tokenId: tokenId,
                percentage: percentage
            })
        );

        emit LayerAssetAdded(parentTokenId, assetAddress, tokenId, percentage);
    }

    // Function to reinvest profits into the parent token and its underlying assets
    function reinvest(uint256 parentTokenId) external nonReentrant {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");

        uint256 profitAmount = profitToken.balanceOf(address(this));
        require(profitAmount > 0, "No profits to reinvest");

        // Reinvest into parent token and its layer assets based on the specified percentages
        for (uint256 i = 0; i < layerAssets[parentTokenId].length; i++) {
            LayerAsset memory layer = layerAssets[parentTokenId][i];
            uint256 reinvestAmount = profitAmount.mul(layer.percentage).div(100);

            // Transfer reinvest amount to the layer asset
            profitToken.transfer(layer.assetAddress, reinvestAmount);
            emit ProfitReinvested(parentTokenId, reinvestAmount, layer.assetAddress, layer.tokenId);
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

    // Function to set profit and reinvest tokens
    function setTokens(address _profitToken, address _reinvestToken) external onlyOwner {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_reinvestToken != address(0), "Invalid reinvest token address");
        profitToken = IERC20(_profitToken);
        reinvestToken = IERC20(_reinvestToken);
    }
}
```

### Key Features and Functionalities:

1. **Multi-Layer Reinvestment**:
   - `addLayerAsset()`: Adds layer assets to a parent token, specifying the percentage of profits to be reinvested in each underlying asset.
   - `reinvest()`: Reinvests profits into the parent token and its underlying layer assets based on their respective percentage allocations.

2. **Profit Management**:
   - `depositProfits()`: Allows the contract owner to deposit profits into the contract for reinvestment.
   - `withdrawProfits()`: Enables the contract owner to withdraw profits from the contract.

3. **Token Management**:
   - `mintComposableToken()`: Mints a new parent composable token to the specified address.

4. **Administrative Functions**:
   - `setTokens()`: Sets or updates the profit and reinvestment tokens used by the contract.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const profitToken = "0x123..."; // Replace with actual profit token address
  const reinvestToken = "0x456..."; // Replace with actual reinvestment token address

  console.log("Deploying contracts with the account:", deployer.address);

  const MultiLayerReinvestmentContract = await ethers.getContractFactory("MultiLayerReinvestmentContract");
  const contract = await MultiLayerReinvestmentContract.deploy("Multi Layer Reinvestment", "MLR", profitToken, reinvestToken);

  console.log("MultiLayerReinvestmentContract deployed to:", contract.address);
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

describe("MultiLayerReinvestmentContract", function () {
  let MultiLayerReinvestmentContract, contract, owner, addr1, profitToken, reinvestToken;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC20 profit and reinvestment tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    profitToken = await ERC20Mock.deploy("Profit Token", "PTK", 18);
    reinvestToken = await ERC20Mock.deploy("Reinvest Token", "RTK", 18);

    MultiLayerReinvestmentContract = await ethers.getContractFactory("MultiLayerReinvestmentContract");
    contract = await MultiLayerReinvestmentContract.deploy("Multi Layer Reinvestment", "MLR", profitToken.address, reinvestToken.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing and approve
    await profitToken.mint(addr1.address, 1000);
    await profitToken.connect(addr1).approve(contract.address, 500);
  });

  it("Should mint a new composable token", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    expect(await contract.ownerOf(1)).to.equal(addr1.address);
  });

  it("Should allow adding layer assets to a composable token", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    await contract.addLayerAsset(1, reinvestToken.address, 1, 50);
    const layerAssets = await contract.layerAssets(1, 0);

    expect(layerAssets.assetAddress).to.equal(reinvestToken.address);
    expect(layerAssets.percentage).to.equal(50);
  });

  it("Should allow depositing profits", async function () {
    await contract.connect(addr1).depositProfits(500);
    expect(await profitToken.balanceOf(contract.address)).to.equal(500);
  });

  it("Should reinvest profits into layer assets", async function () {
    await contract.mintComposableToken(addr1.address, 1);
    await contract.addLayerAsset(1, reinvestToken.address, 1, 100);

    await contract.connect(addr1).depositProfits(500);
    await contract.reinvest(1);

    // Check if profits were reinvested
    expect(await profitToken.balanceOf(reinvestToken.address)).to.equal(500);
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

1. **Dynamic Layer Allocation**: Implement functions to dynamically adjust the allocation percentages of each layer asset based on real-time performance metrics.
2. **Advanced Governance**

: Integrate on-chain voting mechanisms to allow token holders to influence reinvestment strategies.
3. **Oracle Integration**: Use Chainlink oracles to fetch external data for automated adjustment of reinvestment strategies.

This smart contract provides a foundational structure for multi-layer reinvestment strategies in composable token systems, adhering to the ERC998 standard and enabling complex asset management and growth.