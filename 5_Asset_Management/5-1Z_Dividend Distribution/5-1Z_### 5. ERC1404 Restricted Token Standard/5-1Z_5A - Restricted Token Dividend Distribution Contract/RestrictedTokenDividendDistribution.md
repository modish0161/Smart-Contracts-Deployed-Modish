### Smart Contract: `RestrictedTokenDividendDistribution.sol`

This smart contract is designed for distributing dividends to holders of ERC1404 restricted tokens. It ensures that only compliant or accredited investors receive dividends by verifying KYC/AML status before distribution. This contract adheres to the ERC1404 standard, providing a compliant, secure, and reliable solution for dividend distribution.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

interface IKYCCompliance {
    function isCompliant(address investor) external view returns (bool);
}

contract RestrictedTokenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ERC1404 Security Token contract
    ERC1404 public restrictedToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // KYC Compliance contract
    IKYCCompliance public kycComplianceContract;

    // Set of compliant investors
    EnumerableSet.AddressSet private compliantInvestors;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 amount);

    // Event emitted when KYC compliance contract is updated
    event KYCComplianceContractUpdated(address indexed kycComplianceContract);

    constructor(
        address _restrictedToken,
        address _dividendToken,
        address _kycComplianceContract
    ) {
        require(_restrictedToken != address(0), "Invalid restricted token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_kycComplianceContract != address(0), "Invalid KYC compliance contract address");

        restrictedToken = ERC1404(_restrictedToken);
        dividendToken = IERC20(_dividendToken);
        kycComplianceContract = IKYCCompliance(_kycComplianceContract);
    }

    // Function to distribute dividends to all compliant investors
    function distributeDividends(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends() external nonReentrant {
        require(kycComplianceContract.isCompliant(msg.sender), "Investor is not compliant");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(msg.sender, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends
    function getUnclaimedDividends(address investor) public view returns (uint256) {
        uint256 holderBalance = restrictedToken.balanceOf(investor);
        uint256 totalSupply = restrictedToken.totalSupply();

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividends.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[investor];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to update KYC compliance contract
    function updateKYCComplianceContract(address _kycComplianceContract) external onlyOwner {
        require(_kycComplianceContract != address(0), "Invalid KYC compliance contract address");
        kycComplianceContract = IKYCCompliance(_kycComplianceContract);
        emit KYCComplianceContractUpdated(_kycComplianceContract);
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

1. **Compliance Verification**:
   - `kycComplianceContract`: Interface to a KYC compliance contract that checks whether an investor is compliant before allowing dividend claims.
   - `claimDividends()`: Ensures that dividends are only claimed by compliant investors.

2. **Dividend Distribution**:
   - `distributeDividends()`: Allows the owner to distribute dividends to compliant investors. It adds the specified amount to the total dividends pool.
   - `DividendsDistributed()`: Event emitted when dividends are distributed.

3. **Dividend Claiming**:
   - `claimDividends()`: Allows compliant restricted token holders to claim their unclaimed dividends.
   - `DividendsClaimed()`: Event emitted when dividends are claimed.

4. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific holder based on their token holdings.

5. **Contract Management**:
   - `updateKYCComplianceContract()`: Allows the owner to update the KYC compliance contract address.
   - `withdrawRemainingDividends()`: Allows the owner to withdraw any remaining undistributed dividends.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const restrictedToken = "0xYourERC1404TokenAddress"; // Replace with actual ERC1404 token address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  const kycComplianceContract = "0xYourKYCComplianceContractAddress"; // Replace with actual KYC compliance contract address

  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedTokenDividendDistribution = await ethers.getContractFactory("RestrictedTokenDividendDistribution");
  const contract = await RestrictedTokenDividendDistribution.deploy(
    restrictedToken,
    dividendToken,
    kycComplianceContract
  );

  console.log("RestrictedTokenDividendDistribution deployed to:", contract.address);
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

describe("RestrictedTokenDividendDistribution", function () {
  let RestrictedTokenDividendDistribution, contract, owner, addr1, addr2, restrictedToken, dividendToken, kycCompliance;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1404 tokens for testing
    const ERC1404Mock = await ethers.getContractFactory("ERC1404Mock");
    restrictedToken = await ERC1404Mock.deploy("TokenName", "TOK", 1);
    
    // Mint ERC1404 tokens for testing
    await restrictedToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), addr1.address, ethers.utils.parseUnits("200", 18));
    await restrictedToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), addr2.address, ethers.utils.parseUnits("300", 18));

    // Mock ERC20 tokens for dividend distribution
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("DividendToken", "DIV", 18);

    // Mint dividend tokens for testing
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("10000", 18));

    // Mock KYC compliance contract
    const KYCComplianceMock = await ethers.getContractFactory("KYCComplianceMock");
    kycCompliance = await KYCComplianceMock.deploy();

    // Deploy main contract
    const RestrictedTokenDividendDistribution = await ethers.getContractFactory("RestrictedTokenDividendDistribution");
    contract = await RestrictedTokenDividendDistribution.deploy(
      restrictedToken.address,
      dividendToken.address,
      kycCompliance.address
    );
  });

  it("Should distribute dividends correctly", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    const unclaimedDividendsAddr1 = await contract.getUnclaimedDividends(addr1.address);
    expect(unclaimedDividendsAddr1).to.equal(ethers.utils.parseUnits("200", 18)); // 200 tokens for addr1

    const unclaimedDividends

Addr2 = await contract.getUnclaimedDividends(addr2.address);
    expect(unclaimedDividendsAddr2).to.equal(ethers.utils.parseUnits("300", 18)); // 300 tokens for addr2
  });

  it("Should allow compliant address to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await kycCompliance.setCompliant(addr1.address, true);
    await contract.connect(addr1).claimDividends();

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("200", 18)); // Full 200 tokens claimed
  });

  it("Should not allow non-compliant address to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await expect(contract.connect(addr2).claimDividends())
      .to.be.revertedWith("Investor is not compliant");
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This contract and accompanying deployment and test scripts ensure secure, compliant, and efficient dividend distribution to restricted token holders, verifying compliance before allowing dividend claims.