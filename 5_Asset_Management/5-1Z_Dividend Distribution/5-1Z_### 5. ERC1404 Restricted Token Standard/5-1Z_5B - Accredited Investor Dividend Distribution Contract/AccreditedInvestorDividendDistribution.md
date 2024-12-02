### Smart Contract: `AccreditedInvestorDividendDistribution.sol`

This smart contract ensures that only accredited investors receive dividends by leveraging the ERC1404 standard. It automatically verifies the accreditation status of investors and distributes dividends accordingly. The contract is suitable for private equity, venture capital, or any other platforms that require compliance with investor eligibility rules.

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

interface IAccreditationCompliance {
    function isAccredited(address investor) external view returns (bool);
}

contract AccreditedInvestorDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ERC1404 Security Token contract
    ERC1404 public restrictedToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Accreditation Compliance contract
    IAccreditationCompliance public accreditationComplianceContract;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 amount);

    // Event emitted when accreditation compliance contract is updated
    event AccreditationComplianceContractUpdated(address indexed accreditationComplianceContract);

    constructor(
        address _restrictedToken,
        address _dividendToken,
        address _accreditationComplianceContract
    ) {
        require(_restrictedToken != address(0), "Invalid restricted token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_accreditationComplianceContract != address(0), "Invalid accreditation compliance contract address");

        restrictedToken = ERC1404(_restrictedToken);
        dividendToken = IERC20(_dividendToken);
        accreditationComplianceContract = IAccreditationCompliance(_accreditationComplianceContract);
    }

    // Function to distribute dividends to all accredited investors
    function distributeDividends(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends() external nonReentrant {
        require(accreditationComplianceContract.isAccredited(msg.sender), "Investor is not accredited");

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

    // Function to update accreditation compliance contract
    function updateAccreditationComplianceContract(address _accreditationComplianceContract) external onlyOwner {
        require(_accreditationComplianceContract != address(0), "Invalid accreditation compliance contract address");
        accreditationComplianceContract = IAccreditationCompliance(_accreditationComplianceContract);
        emit AccreditationComplianceContractUpdated(_accreditationComplianceContract);
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

1. **Accreditation Verification**:
   - `accreditationComplianceContract`: Interface to an accreditation compliance contract that checks whether an investor is accredited before allowing dividend claims.
   - `claimDividends()`: Ensures that dividends are only claimed by accredited investors.

2. **Dividend Distribution**:
   - `distributeDividends()`: Allows the owner to distribute dividends to accredited investors. It adds the specified amount to the total dividends pool.
   - `DividendsDistributed()`: Event emitted when dividends are distributed.

3. **Dividend Claiming**:
   - `claimDividends()`: Allows accredited restricted token holders to claim their unclaimed dividends.
   - `DividendsClaimed()`: Event emitted when dividends are claimed.

4. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific holder based on their token holdings.

5. **Contract Management**:
   - `updateAccreditationComplianceContract()`: Allows the owner to update the accreditation compliance contract address.
   - `withdrawRemainingDividends()`: Allows the owner to withdraw any remaining undistributed dividends.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const restrictedToken = "0xYourERC1404TokenAddress"; // Replace with actual ERC1404 token address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  const accreditationComplianceContract = "0xYourAccreditationComplianceContractAddress"; // Replace with actual accreditation compliance contract address

  console.log("Deploying contracts with the account:", deployer.address);

  const AccreditedInvestorDividendDistribution = await ethers.getContractFactory("AccreditedInvestorDividendDistribution");
  const contract = await AccreditedInvestorDividendDistribution.deploy(
    restrictedToken,
    dividendToken,
    accreditationComplianceContract
  );

  console.log("AccreditedInvestorDividendDistribution deployed to:", contract.address);
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

describe("AccreditedInvestorDividendDistribution", function () {
  let AccreditedInvestorDividendDistribution, contract, owner, addr1, addr2, restrictedToken, dividendToken, accreditationCompliance;

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

    // Mock Accreditation compliance contract
    const AccreditationComplianceMock = await ethers.getContractFactory("AccreditationComplianceMock");
    accreditationCompliance = await AccreditationComplianceMock.deploy();

    // Deploy main contract
    const AccreditedInvestorDividendDistribution = await ethers.getContractFactory("AccreditedInvestorDividendDistribution");
    contract = await AccreditedInvestorDividendDistribution.deploy(
      restrictedToken.address,
      dividendToken.address,
      accreditationCompliance.address
    );
  });

  it("Should distribute dividends correctly", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    const unclaimedDividendsAddr1 = await contract.getUnclaimedDividends(addr1.address);
    expect(unclaimedDividendsAddr1).to.equal(ethers.utils.parseUnits("200", 18)); // 200 tokens for addr1

    const

 unclaimedDividendsAddr2 = await contract.getUnclaimedDividends(addr2.address);
    expect(unclaimedDividendsAddr2).to.equal(ethers.utils.parseUnits("300", 18)); // 300 tokens for addr2
  });

  it("Should allow accredited investor to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await accreditationCompliance.setAccredited(addr1.address, true);
    await contract.connect(addr1).claimDividends();

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("200", 18)); // Full 200 tokens claimed
  });

  it("Should not allow non-accredited investor to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await expect(contract.connect(addr2).claimDividends())
      .to.be.revertedWith("Investor is not accredited");
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This smart contract implementation, along with deployment and test scripts, provides a secure and compliant way to distribute dividends only to accredited investors.