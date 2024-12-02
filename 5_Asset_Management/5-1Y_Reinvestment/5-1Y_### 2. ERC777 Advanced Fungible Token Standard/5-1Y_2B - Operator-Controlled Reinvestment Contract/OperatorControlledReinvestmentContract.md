### Smart Contract: `OperatorControlledReinvestmentContract.sol`

This contract allows designated operators (e.g., fund managers) to reinvest dividends or profits on behalf of token holders. Using the ERC777 standard, operators have the flexibility to decide which tokens or assets the profits are reinvested into, optimizing portfolio growth based on predefined strategies.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OperatorControlledReinvestmentContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // Dividend Token Interface
    IERC777 public dividendToken;

    // Mapping for operator status
    mapping(address => bool) public isOperator;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 amount, address investmentToken);
    event OperatorUpdated(address indexed operator, bool status);

    // Constructor to initialize the contract with the dividend token
    constructor(address _dividendToken) {
        require(_dividendToken != address(0), "Invalid dividend token address");

        dividendToken = IERC777(_dividendToken);

        // Register this contract as an ERC777 token recipient and sender
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    // Function to deposit dividends (ERC777 tokens)
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.operatorSend(msg.sender, address(this), amount, "", "");
        userDividendBalances[msg.sender] += amount;

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function for operator to reinvest profits on behalf of users
    function reinvestProfits(address user, uint256 amount, address investmentToken) external whenNotPaused nonReentrant onlyOperator {
        require(userDividendBalances[user] >= amount, "Insufficient balance for reinvestment");
        require(investmentToken.isContract(), "Invalid investment token address");

        // Transfer the specified amount to the investment token contract
        dividendToken.operatorSend(address(this), investmentToken, amount, "", "");
        
        // Update the user's balance
        userDividendBalances[user] -= amount;

        emit ProfitsReinvested(user, amount, investmentToken);
    }

    // Function to add or remove operators
    function updateOperator(address operator, bool status) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        isOperator[operator] = status;

        emit OperatorUpdated(operator, status);
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // ERC777 token recipient hook
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called whenever the contract receives ERC777 tokens
        // Implement any necessary logic for handling received tokens here
    }

    // ERC777 token sender hook
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called whenever the contract sends ERC777 tokens
        // Implement any necessary logic for handling sent tokens here
    }

    // Internal function to get the ERC1820 registry address
    function _getERC1820Registry() internal pure returns (address) {
        return 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    }

    // Modifier to restrict functions to designated operators
    modifier onlyOperator() {
        require(isOperator[msg.sender], "Caller is not an operator");
        _;
    }
}
```

### Key Features and Functionalities:

1. **Dividend Deposit and Reinvestment**:
   - `depositDividends()`: Allows users to deposit dividends in the form of ERC777 tokens.
   - `reinvestProfits()`: Allows designated operators to reinvest dividends on behalf of users into specified investment tokens.

2. **Operator Management**:
   - `updateOperator()`: Allows the contract owner to add or remove operators who can control reinvestment processes.

3. **Administrative Controls**:
   - `pause()` and `unpause()`: Allows the contract owner to pause and resume contract operations for security or administrative reasons.

4. **ERC777 Integration**:
   - `tokensReceived()` and `tokensToSend()`: ERC777 hooks to handle received and sent tokens as required by the standard.

### Deployment Script

Create a deployment script using Hardhat:

```javascript
// scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  const dividendTokenAddress = "0x123..."; // Replace with actual dividend token address

  console.log("Deploying contracts with the account:", deployer.address);

  const OperatorControlledReinvestmentContract = await ethers.getContractFactory("OperatorControlledReinvestmentContract");
  const contract = await OperatorControlledReinvestmentContract.deploy(dividendTokenAddress);

  console.log("OperatorControlledReinvestmentContract deployed to:", contract.address);
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

describe("OperatorControlledReinvestmentContract", function () {
  let OperatorControlledReinvestmentContract, contract, owner, addr1, addr2, dividendToken;
  const operator = ethers.provider.getSigner(1);

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Mock ERC777 token for testing
    const ERC777Mock = await ethers.getContractFactory("ERC777Mock");
    dividendToken = await ERC777Mock.deploy("Dividend Token", "DIV");

    OperatorControlledReinvestmentContract = await ethers.getContractFactory("OperatorControlledReinvestmentContract");
    contract = await OperatorControlledReinvestmentContract.deploy(dividendToken.address);
    await contract.deployed();

    // Mint some tokens to addr1 for testing
    await dividendToken.mint(addr1.address, ethers.utils.parseEther("50"));
  });

  it("Should deposit dividends and update user balance", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("20"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("20"));
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("20"));
  });

  it("Should allow operator to reinvest profits", async function () {
    await contract.updateOperator(await operator.getAddress(), true);

    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("30"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("30"));

    await dividendToken.mint(contract.address, ethers.utils.parseEther("30")); // Mint tokens to contract for testing

    await contract.connect(operator).reinvestProfits(addr1.address, ethers.utils.parseEther("30"), dividendToken.address);
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("0"));
    expect(await dividendToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseEther("50"));
  });

  it("Should not allow non-operators to reinvest profits", async function () {
    await dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("10"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("10"));

    await dividendToken.mint(contract.address, ethers.utils.parseEther("10")); // Mint tokens to contract for testing

    await expect(contract.connect(addr2).reinvestProfits(addr1.address, ethers.utils.parseEther("10"), dividendToken.address)).to.be.revertedWith("Caller is not an operator");
  });

  it("Should update operator status", async function () {
    await contract.updateOperator(await operator.getAddress(), true);
    expect(await contract.isOperator(await operator.getAddress())).to.be.true;

    await contract.updateOperator(await operator.getAddress(), false);
    expect(await contract.isOperator(await operator.getAddress())).to.be.false;
  });

  it("Should pause and unpause the contract", async function () {
    await contract.pause();
    await expect(contract.connect(addr1).depositDividends(ethers.utils.parseEther("10"))).to.be.revertedWith("Pausable: paused");

    await contract.unpause();
    await

 dividendToken.connect(addr1).approve(contract.address, ethers.utils.parseEther("10"));
    await contract.connect(addr1).depositDividends(ethers.utils.parseEther("10"));
    expect(await contract.userDividendBalances(addr1.address)).to.equal(ethers.utils.parseEther("10"));
  });
});
```

Run the test suite using:

```bash
npx hardhat test
```

This will deploy the contract, verify its functionality through unit tests, and ensure that the logic behaves as expected. Further customization can be done based on specific requirements.