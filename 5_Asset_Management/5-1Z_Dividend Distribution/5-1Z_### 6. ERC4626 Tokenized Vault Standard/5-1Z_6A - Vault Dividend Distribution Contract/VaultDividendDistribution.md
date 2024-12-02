### Smart Contract: `VaultDividendDistribution.sol`

This smart contract uses the ERC4626 standard to distribute dividends or yields generated from a tokenized vault to its participants. The contract automatically distributes profits based on the vault tokens held by participants.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC4626/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC4626/extensions/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VaultDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC4626 Tokenized Vault
    IERC4626 public vaultToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 amount);

    constructor(address _vaultToken, address _dividendToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        require(_dividendToken != address(0), "Invalid dividend token address");

        vaultToken = IERC4626(_vaultToken);
        dividendToken = IERC20(_dividendToken);
    }

    // Function to distribute dividends to all vault participants
    function distributeDividends(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends() external nonReentrant {
        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(msg.sender, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends
    function getUnclaimedDividends(address investor) public view returns (uint256) {
        uint256 vaultBalance = vaultToken.balanceOf(investor);
        uint256 totalVaultSupply = vaultToken.totalSupply();

        if (totalVaultSupply == 0) return 0;

        uint256 entitledDividends = (totalDividends.mul(vaultBalance)).div(totalVaultSupply);
        uint256 claimedAmount = claimedDividends[investor];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to withdraw remaining dividends (onlyOwner)
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
```

### Key Features and Functionalities:

1. **Dividend Distribution**:
   - `distributeDividends()`: Allows the contract owner to distribute dividends to vault participants based on their token holdings.
   - `DividendsDistributed()`: Event emitted when dividends are distributed.

2. **Dividend Claiming**:
   - `claimDividends()`: Allows participants to claim their unclaimed dividends.
   - `DividendsClaimed()`: Event emitted when dividends are claimed.

3. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific participant based on the number of vault tokens held.

4. **Contract Management**:
   - `withdrawRemainingDividends()`: Allows the owner to withdraw any remaining undistributed dividends from the contract.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const vaultToken = "0xYourERC4626VaultTokenAddress"; // Replace with actual ERC4626 tokenized vault address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address

  console.log("Deploying contracts with the account:", deployer.address);

  const VaultDividendDistribution = await ethers.getContractFactory("VaultDividendDistribution");
  const contract = await VaultDividendDistribution.deploy(
    vaultToken,
    dividendToken
  );

  console.log("VaultDividendDistribution deployed to:", contract.address);
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

describe("VaultDividendDistribution", function () {
  let VaultDividendDistribution, contract, owner, addr1, addr2, vaultToken, dividendToken;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC4626 tokenized vault for testing
    const ERC4626Mock = await ethers.getContractFactory("ERC4626Mock");
    vaultToken = await ERC4626Mock.deploy("Vault Token", "VTOK", 18);
    
    // Mint ERC4626 tokens for testing
    await vaultToken.mint(addr1.address, ethers.utils.parseUnits("200", 18));
    await vaultToken.mint(addr2.address, ethers.utils.parseUnits("300", 18));

    // Mock ERC20 token for dividend distribution
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DIV", 18);

    // Mint dividend tokens for testing
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("10000", 18));

    // Deploy main contract
    const VaultDividendDistribution = await ethers.getContractFactory("VaultDividendDistribution");
    contract = await VaultDividendDistribution.deploy(
      vaultToken.address,
      dividendToken.address
    );
  });

  it("Should distribute dividends correctly", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    const unclaimedDividendsAddr1 = await contract.getUnclaimedDividends(addr1.address);
    expect(unclaimedDividendsAddr1).to.equal(ethers.utils.parseUnits("200", 18)); // 200 tokens for addr1

    const unclaimedDividendsAddr2 = await contract.getUnclaimedDividends(addr2.address);
    expect(unclaimedDividendsAddr2).to.equal(ethers.utils.parseUnits("300", 18)); // 300 tokens for addr2
  });

  it("Should allow vault participant to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await contract.connect(addr1).claimDividends();

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("200", 18)); // Full 200 tokens claimed
  });

  it("Should not allow non-vault participant to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await expect(contract.connect(addr2).claimDividends())
      .to.be.revertedWith("No unclaimed dividends");
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This implementation ensures that dividends or yields generated from the tokenized vault are distributed proportionally to vault participants based on their holdings, adhering to the ERC4626 standard.