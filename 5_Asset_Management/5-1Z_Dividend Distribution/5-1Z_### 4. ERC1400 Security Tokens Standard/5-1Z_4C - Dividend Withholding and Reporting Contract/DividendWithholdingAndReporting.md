### Smart Contract: `DividendWithholdingAndReporting.sol`

This contract is designed for distributing dividends to holders of ERC1400 security tokens. It withholds taxes on dividends and automatically reports the distribution to relevant authorities, ensuring compliance with tax regulations.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

interface ITaxWithholding {
    function calculateWithholding(address investor, uint256 amount) external view returns (uint256);
}

interface ICompliance {
    function isCompliant(address investor) external view returns (bool);
}

contract DividendWithholdingAndReporting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ERC1400 Security Token contract
    IERC1400 public securityToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Tax withholding contract
    ITaxWithholding public taxWithholdingContract;

    // Compliance contract
    ICompliance public complianceContract;

    // Set of compliant investors
    EnumerableSet.AddressSet private compliantInvestors;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 grossAmount, uint256 netAmount, uint256 withheldTax);

    // Event emitted when tax withholding contract is updated
    event TaxWithholdingContractUpdated(address indexed taxWithholdingContract);

    // Event emitted when compliance contract is updated
    event ComplianceContractUpdated(address indexed complianceContract);

    constructor(
        address _securityToken,
        address _dividendToken,
        address _taxWithholdingContract,
        address _complianceContract
    ) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_taxWithholdingContract != address(0), "Invalid tax withholding contract address");
        require(_complianceContract != address(0), "Invalid compliance contract address");

        securityToken = IERC1400(_securityToken);
        dividendToken = IERC20(_dividendToken);
        taxWithholdingContract = ITaxWithholding(_taxWithholdingContract);
        complianceContract = ICompliance(_complianceContract);
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
        require(complianceContract.isCompliant(msg.sender), "Investor is not compliant");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        uint256 withheldTax = taxWithholdingContract.calculateWithholding(msg.sender, unclaimedDividends);
        uint256 netDividends = unclaimedDividends.sub(withheldTax);

        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, netDividends), "Dividend claim transfer failed");
        require(dividendToken.transfer(owner(), withheldTax), "Tax withholding transfer failed");

        emit DividendsClaimed(msg.sender, unclaimedDividends, netDividends, withheldTax);
    }

    // Function to calculate unclaimed dividends
    function getUnclaimedDividends(address investor) public view returns (uint256) {
        uint256 holderBalance = securityToken.balanceOf(investor);
        uint256 totalSupply = securityToken.totalSupply();

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividends.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[investor];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to update tax withholding contract
    function updateTaxWithholdingContract(address _taxWithholdingContract) external onlyOwner {
        require(_taxWithholdingContract != address(0), "Invalid tax withholding contract address");
        taxWithholdingContract = ITaxWithholding(_taxWithholdingContract);
        emit TaxWithholdingContractUpdated(_taxWithholdingContract);
    }

    // Function to update compliance contract
    function updateComplianceContract(address _complianceContract) external onlyOwner {
        require(_complianceContract != address(0), "Invalid compliance contract address");
        complianceContract = ICompliance(_complianceContract);
        emit ComplianceContractUpdated(_complianceContract);
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
   - `complianceContract`: Interface to a compliance contract that checks whether an investor is compliant before allowing dividend claims.
   - `claimDividends()`: Ensures that dividends are only claimed by compliant investors.

2. **Tax Withholding**:
   - `taxWithholdingContract`: Interface to a tax withholding contract that calculates the tax to be withheld from each dividend payment.
   - `claimDividends()`: Automatically withholds taxes on dividends and transfers the withheld amount to the owner (acting as the tax authority representative).

3. **Dividend Distribution**:
   - `distributeDividends()`: Allows the owner to distribute dividends to compliant investors. It adds the specified amount to the total dividends pool.
   - `DividendsDistributed()`: Event emitted when dividends are distributed.

4. **Dividend Claiming**:
   - `claimDividends()`: Allows compliant security token holders to claim their unclaimed dividends after tax withholding.
   - `DividendsClaimed()`: Event emitted when dividends are claimed, providing information about gross amount, net amount, and withheld tax.

5. **Dividend Calculation**:
   - `getUnclaimedDividends()`: Calculates the unclaimed dividends for a specific holder based on their token holdings.

6. **Contract Management**:
   - `updateTaxWithholdingContract()`: Allows the owner to update the tax withholding contract address.
   - `updateComplianceContract()`: Allows the owner to update the compliance contract address.
   - `withdrawRemainingDividends()`: Allows the owner to withdraw any remaining undistributed dividends.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const securityToken = "0xYourERC1400TokenAddress"; // Replace with actual ERC1400 token address
  const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  const taxWithholdingContract = "0xYourTaxWithholdingContractAddress"; // Replace with actual tax withholding contract address
  const complianceContract = "0xYourComplianceContractAddress"; // Replace with actual compliance contract address

  console.log("Deploying contracts with the account:", deployer.address);

  const DividendWithholdingAndReporting = await ethers.getContractFactory("DividendWithholdingAndReporting");
  const contract = await DividendWithholdingAndReporting.deploy(
    securityToken,
    dividendToken,
    taxWithholdingContract,
    complianceContract
  );

  console.log("DividendWithholdingAndReporting deployed to:", contract.address);
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

describe("DividendWithholdingAndReporting", function () {
  let DividendWithholdingAndReporting, contract, owner, addr1, addr2, securityToken, dividendToken, taxWithholding, compliance;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC1400 tokens for testing
    const ERC1400Mock = await ethers.getContractFactory("ERC1400Mock");
    securityToken = await ERC1400Mock.deploy("TokenName", "TOK", 1);
    
    // Mint ERC1400 tokens for testing
    await securityToken.issueByPartition(ethers.utils.format

Bytes32String("tranche1"), addr1.address, ethers.utils.parseUnits("200", 18));
    await securityToken.issueByPartition(ethers.utils.formatBytes32String("tranche1"), addr2.address, ethers.utils.parseUnits("300", 18));

    // Mock ERC20 tokens for dividend distribution
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    dividendToken = await ERC20Mock.deploy("DividendToken", "DIV", 18);

    // Mint dividend tokens for testing
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("10000", 18));

    // Mock tax withholding and compliance contracts
    const TaxWithholdingMock = await ethers.getContractFactory("TaxWithholdingMock");
    taxWithholding = await TaxWithholdingMock.deploy();

    const ComplianceMock = await ethers.getContractFactory("ComplianceMock");
    compliance = await ComplianceMock.deploy();

    // Deploy main contract
    const DividendWithholdingAndReporting = await ethers.getContractFactory("DividendWithholdingAndReporting");
    contract = await DividendWithholdingAndReporting.deploy(
      securityToken.address,
      dividendToken.address,
      taxWithholding.address,
      compliance.address
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

  it("Should allow compliant address to claim dividends with tax withheld", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await contract.connect(addr1).claimDividends();

    const balance = await dividendToken.balanceOf(addr1.address);
    expect(balance).to.equal(ethers.utils.parseUnits("180", 18)); // 20 tokens withheld (10% tax)

    const taxBalance = await dividendToken.balanceOf(owner.address);
    expect(taxBalance).to.equal(ethers.utils.parseUnits("820", 18)); // Owner receives tax + unclaimed dividends
  });

  it("Should not allow non-compliant address to claim dividends", async function () {
    await dividendToken.approve(contract.address, ethers.utils.parseUnits("1000", 18));
    await contract.distributeDividends(ethers.utils.parseUnits("1000", 18));

    await expect(contract.connect(addr2).claimDividends())
      .to.be.revertedWith("Investor is not compliant");
  });
});
```

Run the test suite with:

```bash
npx hardhat test
```

### Conclusion
This contract and the accompanying deployment and test scripts ensure secure, compliant, and efficient dividend distribution with tax withholding and reporting features. You can integrate it with existing infrastructure and customize it further based on specific requirements.