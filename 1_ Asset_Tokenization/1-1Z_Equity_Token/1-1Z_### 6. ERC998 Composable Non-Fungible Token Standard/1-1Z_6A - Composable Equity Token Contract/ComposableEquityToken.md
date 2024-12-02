### Solidity Smart Contract for `Composable Equity Token Contract`

This contract will utilize the ERC998 standard to create composable tokens that can bundle multiple ERC20 equity tokens into a single composable NFT.

#### Contract Code: `ComposableEquityToken.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ComposableEquityToken is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    struct EquityBundle {
        uint256[] tokenIds;
        address[] equityTokens;
        uint256[] amounts;
    }

    mapping(uint256 => EquityBundle) private _bundles;
    uint256 private _nextTokenId;

    event BundleCreated(uint256 indexed bundleId, address indexed owner);
    event EquityAdded(uint256 indexed bundleId, address equityToken, uint256 amount);
    event EquityRemoved(uint256 indexed bundleId, address equityToken, uint256 amount);

    constructor() ERC721("Composable Equity Token", "CET") {}

    function createBundle() external whenNotPaused nonReentrant returns (uint256) {
        uint256 bundleId = _nextTokenId++;
        _mint(msg.sender, bundleId);

        emit BundleCreated(bundleId, msg.sender);
        return bundleId;
    }

    function addEquityToBundle(uint256 bundleId, address equityToken, uint256 amount) external whenNotPaused nonReentrant {
        require(ownerOf(bundleId) == msg.sender, "Not the owner of the bundle");
        require(IERC20(equityToken).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        _bundles[bundleId].equityTokens.push(equityToken);
        _bundles[bundleId].amounts.push(amount);

        emit EquityAdded(bundleId, equityToken, amount);
    }

    function removeEquityFromBundle(uint256 bundleId, address equityToken, uint256 amount) external whenNotPaused nonReentrant {
        require(ownerOf(bundleId) == msg.sender, "Not the owner of the bundle");

        EquityBundle storage bundle = _bundles[bundleId];
        bool found = false;
        for (uint256 i = 0; i < bundle.equityTokens.length; i++) {
            if (bundle.equityTokens[i] == equityToken && bundle.amounts[i] >= amount) {
                bundle.amounts[i] -= amount;
                if (bundle.amounts[i] == 0) {
                    _removeEquity(bundle, i);
                }
                found = true;
                break;
            }
        }
        require(found, "Equity not found or insufficient amount");

        require(IERC20(equityToken).transfer(msg.sender, amount), "Transfer failed");
        emit EquityRemoved(bundleId, equityToken, amount);
    }

    function getBundleDetails(uint256 bundleId) external view returns (address[] memory, uint256[] memory) {
        require(_exists(bundleId), "Bundle does not exist");
        return (_bundles[bundleId].equityTokens, _bundles[bundleId].amounts);
    }

    function _removeEquity(EquityBundle storage bundle, uint256 index) private {
        require(index < bundle.equityTokens.length, "Index out of bounds");

        for (uint256 i = index; i < bundle.equityTokens.length - 1; i++) {
            bundle.equityTokens[i] = bundle.equityTokens[i + 1];
            bundle.amounts[i] = bundle.amounts[i + 1];
        }

        bundle.equityTokens.pop();
        bundle.amounts.pop();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Deployment Script (`deploy.js`)

Create a deployment script using Hardhat for deploying the `ComposableEquityToken.sol` contract.

```javascript
// deploy.js
const hre = require("hardhat");

async function main() {
  // Compile the contract
  const ComposableEquityToken = await hre.ethers.getContractFactory("ComposableEquityToken");

  // Deploy the contract
  const composableEquityToken = await ComposableEquityToken.deploy();

  // Wait for the contract to be deployed
  await composableEquityToken.deployed();

  // Log the address of the deployed contract
  console.log("ComposableEquityToken deployed to:", composableEquityToken.address);
}

// Run the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Testing Script (`test/ComposableEquityToken.test.js`)

Create a testing script to verify the core functionalities of the `ComposableEquityToken` contract using Mocha, Chai, and Hardhat Waffle.

```javascript
// test/ComposableEquityToken.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComposableEquityToken", function () {
  let owner, user1, user2;
  let equityToken1, equityToken2, composableEquityToken;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock equity token 1 for testing
    const EquityToken = await ethers.getContractFactory("ERC20");
    equityToken1 = await EquityToken.deploy("Equity Token 1", "EQTY1", ethers.utils.parseUnits("1000", 18));
    await equityToken1.deployed();

    // Deploy a mock equity token 2 for testing
    equityToken2 = await EquityToken.deploy("Equity Token 2", "EQTY2", ethers.utils.parseUnits("1000", 18));
    await equityToken2.deployed();

    // Deploy the ComposableEquityToken contract
    const ComposableEquityToken = await ethers.getContractFactory("ComposableEquityToken");
    composableEquityToken = await ComposableEquityToken.deploy();
    await composableEquityToken.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await composableEquityToken.owner()).to.equal(owner.address);
    });
  });

  describe("Creating and Managing Bundles", function () {
    it("Should create a new bundle", async function () {
      const bundleId = await composableEquityToken.createBundle();
      expect(bundleId).to.exist;
      expect(await composableEquityToken.ownerOf(bundleId)).to.equal(owner.address);
    });

    it("Should allow adding equity to a bundle", async function () {
      // Create a bundle
      await composableEquityToken.createBundle();

      // Approve and add equity to the bundle
      await equityToken1.approve(composableEquityToken.address, ethers.utils.parseUnits("100", 18));
      await composableEquityToken.addEquityToBundle(0, equityToken1.address, ethers.utils.parseUnits("100", 18));

      // Check bundle details
      const [equityTokens, amounts] = await composableEquityToken.getBundleDetails(0);
      expect(equityTokens).to.include(equityToken1.address);
      expect(amounts[0]).to.equal(ethers.utils.parseUnits("100", 18));
    });

    it("Should allow removing equity from a bundle", async function () {
      // Create a bundle
      await composableEquityToken.createBundle();

      // Approve and add equity to the bundle
      await equityToken1.approve(composableEquityToken.address, ethers.utils.parseUnits("100", 18));
      await composableEquityToken.addEquityToBundle(0, equityToken1.address, ethers.utils.parseUnits("100", 18));

      // Remove equity from the bundle
      await composableEquityToken.removeEquityFromBundle(0, equityToken1.address, ethers.utils.parseUnits("50", 18));

      // Check bundle details
      const [equityTokens, amounts] = await composableEquityToken.getBundleDetails(0);
      expect(amounts[0]).to.equal(ethers.utils.parseUnits("50", 18));
    });

    it("Should emit events on adding and removing equity", async function () {
      // Create a bundle
      await composableEquityToken.createBundle();

      // Approve and add equity to the bundle
      await equityToken1.approve(composableEquityToken.address, ethers.utils.parseUnits("100", 18));
      await expect(composableEquityToken.addEquityToBundle(0, equityToken1.address, ethers.utils.parseUnits("100", 18)))
        .to.emit(composableEquityToken, "EquityAdded")
        .withArgs(0, equityToken1.address, ethers.utils.parseUnits("100", 18));

      // Remove equity from the bundle
      await expect(composableEquityToken.removeEquityFromBundle(0, equityToken1.address, ethers.utils.parseUnits("50", 18)))
        .to.emit(composableEquityToken, "EquityRemoved")
        .withArgs(0, equityToken1.address, ethers.utils.parseUnits("50", 18));
    });
  });

  describe("Pausable Functionality", function () {
    it("Should allow the owner to pause and unpause the contract", async function () {
      // Pause the contract
      await composable

EquityToken.pause();
      expect(await composableEquityToken.paused()).to.be.true;

      // Unpause the contract
      await composableEquityToken.unpause();
      expect(await composableEquityToken.paused()).to.be.false;
    });

    it("Should revert when performing actions while paused", async function () {
      // Pause the contract
      await composableEquityToken.pause();

      // Try to create a bundle
      await expect(composableEquityToken.createBundle()).to.be.revertedWith("Pausable: paused");
    });
  });
});
```

### Deployment and Testing Instructions

1. **Install Dependencies**:
   ```bash
   npm install --save-dev @openzeppelin/contracts hardhat ethers mocha chai
   ```

2. **Deploy the Contract**:
   ```bash
   npx hardhat run scripts/deploy.js --network <your_network>
   ```

3. **Run the Tests**:
   ```bash
   npx hardhat test
   ```

This setup provides a complete smart contract for the `ComposableEquityToken.sol` using the ERC998 standard, along with deployment and testing scripts to ensure the contract functions correctly.