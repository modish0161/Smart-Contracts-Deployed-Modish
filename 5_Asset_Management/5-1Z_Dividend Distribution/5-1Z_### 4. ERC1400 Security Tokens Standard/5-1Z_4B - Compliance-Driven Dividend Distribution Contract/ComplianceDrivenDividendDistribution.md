### Smart Contract: `ComplianceDrivenDividendDistribution.sol`

This contract is designed for distributing dividends to holders of ERC1400 security tokens, ensuring that only compliant or accredited investors receive dividends. It incorporates compliance checks and security measures to ensure adherence to regulatory requirements.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

interface ICompliance {
    function isCompliant(address investor) external view returns (bool);
}

contract ComplianceDrivenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC1400 Security Token contract
    IERC1400 public securityToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Compliance contract address
    ICompliance public complianceContract;

    // Total dividends available for each tranche
    mapping(bytes32 => uint256) public totalDividends;

    // Dividends claimed by each address for each tranche
    mapping(address => mapping(bytes32 => uint256)) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(bytes32 indexed tranche, uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed holder, bytes32 indexed tranche, uint256 amount);

    // Event emitted when compliance contract is updated
    event ComplianceContractUpdated(address indexed complianceContract);

    constructor(
        address _securityToken,
        address _dividendToken,
        address _complianceContract
    ) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_complianceContract != address(0), "Invalid compliance contract address");

        securityToken = IERC1400(_securityToken);
        dividendToken = IERC20(_dividendToken);
        complianceContract = ICompliance(_complianceContract);
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
        require(complianceContract.isCompliant(msg.sender), "Investor is not compliant");

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

    // Function to update compliance contract address
    function updateComplianceContract(address _complianceContract) external onlyOwner {
        require(_complianceContract != address(0), "Invalid compliance contract address");
        complianceContract = ICompliance(_complianceContract);
        emit ComplianceContractUpdated(_complianceContract);
    }
}
```

### Key Features and Functionalities:

1. **Compliance Verification**:
   - `complianceContract`: Interface to a compliance contract that checks whether an investor is compliant.
   - `claimDividends()`: Only allows dividend claims if the investor is compliant, ensuring regulatory adherence.

2. **Dividend Distribution**:
   - `distributeDividends()`: Allows the owner to distribute dividends for a specific tranche (partition) of security tokens. It adds the specified amount to the total dividends for the tranche.
   - `DividendsDistributed()`: Event emitted when dividends are distributed for a tranche.

3. **Dividend Claiming**:
   - `claimDividends()`: Allows compliant security token holders to claim their unclaimed dividends for a specific tranche. It calculates the unclaimed dividends based on their token holdings in that tranche.
   - `DividendsClaimed()`: Event emitted when dividends are claimed for a tranche by a holder.

4. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific holder and tranche, considering their holdings and the total dividends distributed for that tranche.

5. **Compliance Contract Management**:
   - `updateComplianceContract()`: Allows the owner to update the compliance contract address, enabling flexibility in compliance provider integration.
   - `ComplianceContractUpdated()`: Event emitted when the compliance contract is updated.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const securityToken = "0xYourERC1400TokenAddress"; // Replace with actual ERC1400 token address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  const complianceContract = "0xYourComplianceContractAddress"; // Replace with actual compliance contract address

  console.log("Deploying contracts with the account:", deployer.address);

  const ComplianceDrivenDividendDistribution = await ethers.getContractFactory("ComplianceDrivenDividendDistribution");
  const contract = await ComplianceDrivenDividendDistribution.deploy(securityToken, dividendToken, complianceContract);

  console.log("ComplianceDrivenDividendDistribution deployed to:", contract.address);
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

describe("ComplianceDrivenDividendDistribution", function () {
  let ComplianceDrivenDividendDistribution, contract, owner, addr1, addr2, securityToken, dividendToken, compliance;

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

    // Mock Compliance contract for testing
    const ComplianceMock = await ethers.getContractFactory("ComplianceMock");
    compliance = await ComplianceMock.deploy();
    await compliance.setCompliant(addr1.address, true); // Only addr1 is compliant

    ComplianceDrivenDividendDistribution = await ethers.getContractFactory("ComplianceDrivenDividendDistribution");
    contract = await ComplianceDrivenDividendDistribution.deploy(securityToken.address, dividendToken.address, compliance.address);
    await contract.deployed();
  });

  it("Should distribute dividends for a tranche", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    const totalDividends = await contract.totalDividends(ethers.utils.formatBytes32String("tranche1"));
    expect(totalDividends).to.equal(ethers.utils.parseUnits("1000", 18));
  });

  it("Should calculate unclaimed dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18

));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    const unclaimedDividends = await contract.getUnclaimedDividends(addr1.address, ethers.utils.formatBytes32String("tranche1"));
    expect(unclaimedDividends).to.equal(ethers.utils.parseUnits("200", 18)); // addr1 holds 200 out of 1000 (20%)
  });

  it("Should allow compliant address to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    await contract.connect(addr1).claimDividends(ethers.utils.formatBytes32String("tranche1"));

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("200", 18)); // addr1 holds 200 out of 1000 (20%)
  });

  it("Should not allow non-compliant address to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.formatBytes32String("tranche1"), ethers.utils.parseUnits("1000", 18));

    await expect(contract.connect(addr2).claimDividends(ethers.utils.formatBytes32String("tranche1")))
      .to.be.revertedWith("Investor is not compliant");
  });
});
```

Run the test suite with:

```bash
npx hardhat test
```

This contract and accompanying deployment and test scripts provide a robust framework for compliant dividend distribution using security tokens.