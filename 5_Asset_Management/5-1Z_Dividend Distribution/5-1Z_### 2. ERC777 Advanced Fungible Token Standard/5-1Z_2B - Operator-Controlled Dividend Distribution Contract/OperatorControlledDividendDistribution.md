### Smart Contract: `OperatorControlledDividendDistribution.sol`

This smart contract uses the ERC777 standard to facilitate dividend distribution controlled by designated operators such as fund managers. It allows both manual and automated dividend payouts based on predefined rules.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OperatorControlledDividendDistribution is Ownable, ReentrancyGuard {
    ERC777 public dividendToken; // ERC777 token used for dividend distribution
    mapping(address => uint256) public dividends; // Mapping of dividends for each holder
    mapping(address => bool) public isOperator; // Mapping of approved operators
    uint256 public totalDividends; // Total dividends available for distribution

    event DividendsDeposited(address indexed from, uint256 amount);
    event DividendsDistributed(address indexed operator, uint256 amount);
    event DividendsClaimed(address indexed holder, uint256 amount);
    event OperatorApproved(address indexed operator);
    event OperatorRevoked(address indexed operator);

    modifier onlyOperator() {
        require(isOperator[msg.sender] || msg.sender == owner(), "Caller is not an operator");
        _;
    }

    constructor(address _dividendToken, address[] memory _operators) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        dividendToken = ERC777(_dividendToken);
        
        // Approve initial operators
        for (uint256 i = 0; i < _operators.length; i++) {
            isOperator[_operators[i]] = true;
            emit OperatorApproved(_operators[i]);
        }
    }

    // Function to deposit dividends into the contract
    function depositDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.send(address(this), _amount, "");
        totalDividends += _amount;

        emit DividendsDeposited(msg.sender, _amount);
    }

    // Function to distribute dividends to all token holders
    function distributeDividends(address[] memory _holders, uint256[] memory _amounts) external onlyOperator nonReentrant {
        require(_holders.length == _amounts.length, "Holders and amounts length mismatch");
        require(totalDividends > 0, "No dividends to distribute");

        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < _holders.length; i++) {
            require(_amounts[i] > 0, "Amount must be greater than zero");
            require(_holders[i] != address(0), "Invalid holder address");

            if (dividends[_holders[i]] == 0) {
                dividends[_holders[i]] = _amounts[i];
            } else {
                dividends[_holders[i]] += _amounts[i];
            }

            totalDistributed += _amounts[i];
        }

        require(totalDistributed <= totalDividends, "Distributed amount exceeds available dividends");
        totalDividends -= totalDistributed;

        emit DividendsDistributed(msg.sender, totalDistributed);
    }

    // Function to claim dividends by a token holder
    function claimDividends() external nonReentrant {
        uint256 amount = dividends[msg.sender];
        require(amount > 0, "No dividends to claim");

        dividends[msg.sender] = 0;
        dividendToken.send(msg.sender, amount, "");

        emit DividendsClaimed(msg.sender, amount);
    }

    // Function to approve a new operator
    function approveOperator(address _operator) external onlyOwner {
        require(!isOperator[_operator], "Already an operator");
        isOperator[_operator] = true;
        emit OperatorApproved(_operator);
    }

    // Function to revoke an operator
    function revokeOperator(address _operator) external onlyOwner {
        require(isOperator[_operator], "Not an operator");
        isOperator[_operator] = false;
        emit OperatorRevoked(_operator);
    }

    // Function to get total dividends available for distribution
    function getTotalDividends() external view returns (uint256) {
        return totalDividends;
    }

    // Function to get dividends of a holder
    function getDividends(address _holder) external view returns (uint256) {
        return dividends[_holder];
    }
}
```

### Key Features and Functionalities:

1. **Operator Control**:
   - `approveOperator()`: Allows the owner to approve a new operator who can distribute dividends.
   - `revokeOperator()`: Allows the owner to revoke an existing operator.
   - `isOperator`: Mapping to track approved operators who can distribute dividends.

2. **Dividend Deposit and Distribution**:
   - `depositDividends()`: Allows the owner to deposit dividends into the contract.
   - `distributeDividends()`: Allows operators to distribute dividends to specified holders based on the amounts provided.

3. **Dividend Claim**:
   - `claimDividends()`: Allows token holders to claim their dividends.

4. **Dividend Tracking**:
   - `dividends`: Mapping of dividends available for each token holder.
   - `getDividends()`: Returns the amount of dividends available for a specific holder.
   - `getTotalDividends()`: Returns the total dividends available for distribution.

5. **Operator Approval Events**:
   - `OperatorApproved()`: Emitted when an operator is approved.
   - `OperatorRevoked()`: Emitted when an operator is revoked.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const dividendToken = "0xYourDividendTokenAddress"; // Replace with actual dividend token address
  const operators = ["0xOperatorAddress1", "0xOperatorAddress2"]; // Replace with actual operator addresses

  console.log("Deploying contracts with the account:", deployer.address);

  const OperatorControlledDividendDistribution = await ethers.getContractFactory("OperatorControlledDividendDistribution");
  const contract = await OperatorControlledDividendDistribution.deploy(dividendToken, operators);

  console.log("OperatorControlledDividendDistribution deployed to:", contract.address);
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

describe("OperatorControlledDividendDistribution", function () {
  let OperatorControlledDividendDistribution, contract, owner, addr1, addr2, dividendToken;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC777 tokens for testing
    const ERC777Mock = await ethers.getContractFactory("ERC777Mock");
    dividendToken = await ERC777Mock.deploy("Dividend Token", "DVT", []);

    OperatorControlledDividendDistribution = await ethers.getContractFactory("OperatorControlledDividendDistribution");
    contract = await OperatorControlledDividendDistribution.deploy(dividendToken.address, [addr1.address]);
    await contract.deployed();

    // Mint and approve tokens for testing
    await dividendToken.mint(owner.address, ethers.utils.parseUnits("10000", 18));
    await dividendToken.mint(addr1.address, ethers.utils.parseUnits("2000", 18));
    await dividendToken.mint(addr2.address, ethers.utils.parseUnits("3000", 18));
  });

  it("Should deposit dividends", async function () {
    await dividendToken.send(contract.address, ethers.utils.parseUnits("1000", 18), []);
    expect(await contract.getTotalDividends()).to.equal(ethers.utils.parseUnits("1000", 18));
  });

  it("Should distribute dividends by operator", async function () {
    await dividendToken.send(contract.address, ethers.utils.parseUnits("1000", 18), []);
    await contract.connect(addr1).distributeDividends([addr1.address, addr2.address], [ethers.utils.parseUnits("500", 18), ethers.utils.parseUnits("500", 18)]);

    expect(await contract.getDividends(addr1.address)).to.equal(ethers.utils.parseUnits("500", 18));
    expect(await contract.getDividends(addr2.address)).to.equal(ethers.utils.parseUnits("500", 18));
  });

  it("Should allow holders to claim dividends", async function () {
    await dividendToken.send(contract.address, ethers.utils.parseUnits("1000", 18), []);
    await contract.connect(addr1).distributeDividends([addr1.address, addr2.address], [ethers.utils.parseUnits("500", 18), ethers.utils.parseUnits("500", 18)]);

    const initialBalance = await dividendToken.balanceOf(addr1.address);
    await contract.connect(addr1).claimDividends();
    const finalBalance = await dividendToken.balanceOf(addr1.address);

    expect(finalBalance).to.be.gt(initialBalance);
  });

  it("Should allow owner to approve and revoke operators", async function () {
    await contract.approveOperator(addr2.address);
    expect(await contract.isOperator(addr2.address)).to.be.true;

    await contract.revokeOperator(addr2.address);
    expect(await contract.isOperator(addr2.address)).to.be.false;
  });
});
```

Run the test suite:

```bash
npx hardhat test
```

### Additional Features & Customization

1. **Advanced Operator Management**

: Implement a more advanced operator management system with multi-signature control.
2. **Enhanced Dividend Logic**: Add conditions such as minimum dividend thresholds or periodic distributions.
3. **Governance Mechanisms**: Implement token-based voting to allow holders to vote on dividend distribution parameters.

This contract leverages the ERC777 standard to create a flexible and secure dividend distribution mechanism that allows for operator control and enhanced payout strategies.