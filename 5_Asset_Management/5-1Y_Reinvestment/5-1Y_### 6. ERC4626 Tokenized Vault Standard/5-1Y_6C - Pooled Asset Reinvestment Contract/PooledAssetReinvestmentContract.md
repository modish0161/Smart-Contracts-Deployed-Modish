### Smart Contract: `PooledAssetReinvestmentContract.sol`

This contract implements the ERC4626 Tokenized Vault Standard, designed to reinvest profits generated by pooled assets in a tokenized vault into additional vault assets or other investment opportunities. It ensures that profits are continuously reinvested to enhance portfolio growth.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PooledAssetReinvestmentContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    ERC4626 public vault;
    IERC20 public assetToken;
    address[] public supportedVaults;
    mapping(address => uint256) public userShares;
    mapping(address => uint256) public reinvestmentStrategy; // Maps user address to vault index for reinvestment

    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 amount);
    event Reinvested(address indexed user, uint256 amount, uint256 shares);
    event StrategyUpdated(address indexed user, uint256 vaultIndex);
    event VaultAdded(address indexed vault);

    constructor(address _vaultAddress) {
        require(_vaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(_vaultAddress);
        assetToken = IERC20(vault.asset());
        supportedVaults.push(_vaultAddress); // Add initial vault to supported list
    }

    // Function to deposit assets into the vault
    function deposit(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(assetToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Approve and deposit into vault
        assetToken.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, address(this));
        
        userShares[msg.sender] = userShares[msg.sender].add(shares);

        emit Deposited(msg.sender, amount, shares);
    }

    // Function to withdraw assets from the vault
    function withdraw(uint256 shares) external whenNotPaused nonReentrant {
        require(userShares[msg.sender] >= shares, "Insufficient shares");

        userShares[msg.sender] = userShares[msg.sender].sub(shares);
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Function to set reinvestment strategy
    function setReinvestmentStrategy(uint256 vaultIndex) external whenNotPaused {
        require(vaultIndex < supportedVaults.length, "Invalid vault index");
        reinvestmentStrategy[msg.sender] = vaultIndex;

        emit StrategyUpdated(msg.sender, vaultIndex);
    }

    // Function to reinvest yield into selected vault based on strategy
    function reinvestYield() external whenNotPaused nonReentrant {
        uint256 totalShares = userShares[msg.sender];
        require(totalShares > 0, "No shares deposited");

        uint256 availableAssets = vault.previewRedeem(totalShares);
        uint256 reinvestmentAmount = availableAssets.mul(10).div(100); // Example: reinvest 10% of yield
        address targetVault = supportedVaults[reinvestmentStrategy[msg.sender]];

        // Withdraw yield from original vault
        vault.redeem(reinvestmentAmount, address(this), address(this));

        // Approve and deposit yield into target vault
        assetToken.approve(targetVault, reinvestmentAmount);
        ERC4626(targetVault).deposit(reinvestmentAmount, address(this));

        // Update user shares for the target vault
        uint256 newShares = ERC4626(targetVault).convertToShares(reinvestmentAmount);
        userShares[msg.sender] = userShares[msg.sender].add(newShares);

        emit Reinvested(msg.sender, reinvestmentAmount, newShares);
    }

    // Function to add a new vault to the supported vault list
    function addVault(address newVault) external onlyOwner {
        require(newVault != address(0), "Invalid vault address");
        supportedVaults.push(newVault);

        emit VaultAdded(newVault);
    }

    // Emergency withdrawal for users in case of a contract malfunction
    function emergencyWithdraw() external nonReentrant {
        uint256 shares = userShares[msg.sender];
        require(shares > 0, "No shares to withdraw");

        userShares[msg.sender] = 0;
        uint256 amount = vault.redeem(shares, msg.sender, address(this));

        emit Withdrawn(msg.sender, shares, amount);
    }

    // Function to pause the contract in case of an emergency
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to update the main vault address
    function updateVault(address newVaultAddress) external onlyOwner {
        require(newVaultAddress != address(0), "Invalid vault address");
        vault = ERC4626(newVaultAddress);
        assetToken = IERC20(vault.asset());
    }
}
```

### Key Features and Functionalities:

1. **Deposit and Withdraw**:
   - `deposit()`: Allows users to deposit assets into the vault, receiving vault shares in return.
   - `withdraw()`: Allows users to redeem their vault shares for the underlying assets, withdrawing from the vault.

2. **Reinvestment Strategy**:
   - `setReinvestmentStrategy()`: Users can set their reinvestment strategy, selecting which vault to reinvest their yield into.
   - `reinvestYield()`: Automatically reinvests yield from the vault into the user's selected vault based on their strategy.

3. **Vault Management**:
   - `addVault()`: Allows the owner to add new vaults to the supported vault list for reinvestment options.
   - `updateVault()`: Allows the owner to update the main vault for asset management.

4. **Emergency Withdrawals**:
   - `emergencyWithdraw()`: Allows users to withdraw all their assets in case of an emergency.

5. **Contract Management**:
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

6. **Security and Governance**:
   - Utilizes `Ownable`, `ReentrancyGuard`, and `Pausable` for enhanced security and administrative controls.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const vaultAddress = "0x123..."; // Replace with actual vault address

  console.log("Deploying contracts with the account:", deployer.address);

  const PooledAssetReinvestmentContract = await ethers.getContractFactory("PooledAssetReinvestmentContract");
  const contract = await PooledAssetReinvestmentContract.deploy(vaultAddress);

  console.log("PooledAssetReinvestmentContract deployed to:", contract.address);
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

describe("PooledAssetReinvestmentContract", function () {
  let PooledAssetReinvestmentContract, contract, owner, addr1, vault, assetToken;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    // Mock ERC4626 vault and asset token for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    assetToken = await ERC20Mock.deploy("Test Asset", "TAS", 18);

    const ERC4626Mock = await ethers.getContractFactory("ERC4626Mock");
    vault = await ERC4626Mock.deploy(assetToken.address);

    PooledAssetReinvestmentContract = await ethers.getContractFactory("PooledAssetReinvestmentContract");
    contract = await PooledAssetReinvestmentContract.deploy(vault.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing and approve
    await assetToken.mint(addr1.address, 1000);
    await assetToken.connect(addr1).approve(contract.address, 500);
  });

  it("Should allow user to deposit assets", async function () {
    await contract.connect(addr1).deposit(500);

    expect(await contract.userShares(addr1.address)).to.be.above(0);
  });

  it("Should allow user to set reinvestment strategy", async function () {
    await contract.connect(addr1).setReinvestmentStrategy(0);

    const strategy = await contract.reinvestmentStrategy(addr1.address);
    expect(strategy).to.equal(0);
  });

  it("Should allow user to reinvest yield", async function () {
    await contract.connect(addr1).deposit(500);
    await contract.connect(addr1).setReinvestmentStrategy(0);

    await contract.connect(addr1).reinvestYield();

    expect(await contract.userShares(addr1.address)).to.be.above(0);
  });

  it("Should allow user to withdraw assets", async function () {
    await contract.connect(addr1).deposit(500);
    await contract.connect(addr1).withdraw(100);

    expect(await contract.userShares(addr1

.address)).to.be.equal(400);
  });

  it("Should allow emergency withdrawal", async function () {
    await contract.connect(addr1).deposit(500);
    await contract.connect(addr1).emergencyWithdraw();

    expect(await contract.userShares(addr1.address)).to.be.equal(0);
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

### Additional Customizations

1. **Yield Optimization**: Implement yield optimization strategies based on real-time performance data from different vaults.
2. **Governance Features**: Add on-chain governance for updating reinvestment strategies and asset allocation rules.
3. **Cross-Chain Reinvestment**: Support reinvestment across multiple blockchains using cross-chain bridges.

This contract provides automated yield reinvestment for tokenized vaults, adhering to the ERC4626 standard, allowing users to benefit from compounded returns.