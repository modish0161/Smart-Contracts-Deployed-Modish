### Smart Contract: `SecurityTokenDividendDistribution.sol`

This smart contract is designed for distributing dividends to holders of security tokens compliant with the ERC1400 standard. It ensures that dividend distribution is conducted securely and in compliance with securities regulations.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract SecurityTokenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC1400 Security Token contract
    IERC1400 public securityToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Total dividends available for each tranche
    mapping(bytes32 => uint256) public totalDividends;

    // Dividends claimed by each address for each tranche
    mapping(address => mapping(bytes32 => uint256)) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(bytes32 indexed tranche, uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed holder, bytes32 indexed tranche, uint256 amount);

    constructor(address _securityToken, address _dividendToken) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_dividendToken != address(0), "Invalid dividend token address");

        securityToken = IERC1400(_securityToken);
        dividendToken = IERC20(_dividendToken);
    }

    // Function to distribute dividends for a specific tranche
    function distributeDividends(bytes32 tranche, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends[tranche] = totalDividends[tranche].add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(tranche, amount);
    }

    // Function to claim dividends for a specific tranche
    function claimDividends(bytes32 tranche) external nonReentrant {
        uint256 holderBalance = securityToken.balanceOfByPartition(tranche, msg.sender);
        require(holderBalance > 0, "No tokens to claim dividends for");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender, tranche);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender][tranche] = claimedDividends[msg.sender][tranche].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(msg.sender, tranche, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends for a holder and tranche
    function getUnclaimedDividends(address holder, bytes32 tranche) public view returns (uint256) {
        uint256 totalDividendsForTranche = totalDividends[tranche];
        uint256 holderBalance = securityToken.balanceOfByPartition(tranche, holder);
        uint256 totalSupply = securityToken.totalSupplyByPartition(tranche);

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividendsForTranche.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[holder][tranche];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }
}
```

### Key Features and Functionalities:

1. **Dividend Distribution**:
   - `distributeDividends()`: Allows the owner to distribute dividends for a specific tranche (partition) of security tokens. It adds the specified amount to the total dividends for the tranche.
   - `DividendsDistributed()`: Event emitted when dividends are distributed for a tranche.

2. **Dividend Claiming**:
   - `claimDividends()`: Allows security token holders to claim their unclaimed dividends for a specific tranche. It calculates the unclaimed dividends based on their token holdings in that tranche.
   - `DividendsClaimed()`: Event emitted when dividends are claimed for a tranche by a holder.

3. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific holder and tranche, considering their holdings and the total dividends distributed for that tranche.

4. **Compliance and Access Control**:
   - The contract uses `Ownable` to restrict dividend distribution to the contract owner, ensuring compliance and preventing unauthorized actions.
   - It integrates with the ERC1400 standard to handle partition-based security tokens.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const securityToken = "0xYourERC1400TokenAddress"; // Replace with actual ERC1400 token address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address

  console.log("Deploying contracts with the account:", deployer.address);

  const SecurityTokenDividendDistribution = await ethers.getContractFactory("SecurityTokenDividendDistribution");
  const contract = await SecurityTokenDividendDistribution.deploy(securityToken, dividendToken);

  console.log("SecurityTokenDividendDistribution deployed to:", contract.address);
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

describe("SecurityTokenDividendDistribution", function () {
  let SecurityTokenDividendDistribution, contract, owner, addr1, addr2, securityToken, dividendToken;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1400 tokens for testing
    const ERC1400Mock = await ethers.getContractFactory("ERC1400Mock");
    securityToken = await ERC1400Mock.deploy("TokenName", "TOK", 1);
    
    // Mint ERC1400 tokens for testing
    await securityToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), owner.address, 1000, []);
    await securityToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), addr1.address, 200, []);
    await securityToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), addr2.address, 300, []);

    // Mock ERC20 tokens for testing
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("Dividend Token", "DIV", 18);
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("1000000", 18));

    SecurityTokenDividendDistribution = await ethers.getContractFactory("SecurityTokenDividendDistribution");
    contract = await SecurityTokenDividendDistribution.deploy(securityToken.address, dividendToken.address);
    await contract.deployed();
  });

  it("Should distribute dividends for a tranche", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    const totalDividends = await contract.totalDividends(ethers.utils.formatBytes32String("tranche1"));
    expect(totalDividends).to.equal(ethers.utils.parseUnits("1000", 18));
  });

  it("Should calculate unclaimed dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    const unclaimedDividends = await contract.getUnclaimedDividends(addr1.address, ethers.utils.formatBytes32String("tranche1"));
    expect(unclaimedDividends).to.equal(ethers.utils.parseUnits("200", 18)); // 200 / 1500 * 1000
  });

  it("Should allow holders to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));
    await contract.connect(addr1).claimDividends(ethers.utils.formatBytes32String("tranche1"));

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.be.equal(ethers.utils.parseUnits("200", 18)); // Claimed dividends
  });
});
```

Run the test suite:

```bash
npx hardhat test
```

### Additional Features & Customization

1. **Compliance Integration**: Integrate the contract with third-party KYC/AML services to ensure that only compliant investors can receive dividends.
2. **Governance Mechanism**: Implement a voting mechanism that allows token holders to decide on dividend distribution policies or special distributions

.
3. **Extended Analytics**: Provide detailed analytics and reports for investors, including historical dividend distributions and portfolio performance.

This smart contract allows for secure and compliant dividend distribution to holders of security tokens, ensuring that the process adheres to the necessary regulations and standards.