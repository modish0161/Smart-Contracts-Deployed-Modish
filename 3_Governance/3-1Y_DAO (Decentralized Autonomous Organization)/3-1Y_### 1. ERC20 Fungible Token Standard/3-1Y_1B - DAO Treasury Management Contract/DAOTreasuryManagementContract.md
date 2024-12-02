### Smart Contract: DAO Treasury Management Contract

Based on the provided requirements, I will create a smart contract called `DAOTreasuryManagementContract.sol` using the ERC20 standard. This contract will allow DAO token holders to propose, vote, and execute decisions regarding the management of the DAO’s treasury, ensuring that all financial resources are managed according to the community consensus.

#### Smart Contract Code (`DAOTreasuryManagementContract.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DAOTreasuryManagementContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    ERC20 public governanceToken;
    uint256 public treasuryBalance;

    struct Proposal {
        string title;
        string description;
        uint256 amount;
        address payable recipient;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public constant VOTING_DURATION = 7 days;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 amount,
        address indexed recipient,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        bool approved,
        uint256 amount,
        address indexed recipient
    );

    constructor(address _governanceToken) {
        governanceToken = ERC20(_governanceToken);
    }

    receive() external payable {
        treasuryBalance = treasuryBalance.add(msg.value);
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 amount,
        address payable recipient
    ) external onlyOwner whenNotPaused {
        require(amount <= treasuryBalance, "Insufficient treasury balance");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            title: title,
            description: description,
            amount: amount,
            recipient: recipient,
            endTime: block.timestamp + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, title, description, amount, recipient, block.timestamp + VOTING_DURATION);
    }

    function vote(uint256 proposalId, bool support) external nonReentrant whenNotPaused {
        require(block.timestamp < proposals[proposalId].endTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        require(voterBalance > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposals[proposalId].yesVotes = proposals[proposalId].yesVotes.add(voterBalance);
        } else {
            proposals[proposalId].noVotes = proposals[proposalId].noVotes.add(voterBalance);
        }

        emit VoteCasted(proposalId, msg.sender, support, voterBalance);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        bool approved = proposal.yesVotes > proposal.noVotes;
        if (approved) {
            require(proposal.amount <= treasuryBalance, "Insufficient treasury balance");
            proposal.recipient.transfer(proposal.amount);
            treasuryBalance = treasuryBalance.sub(proposal.amount);
        }

        emit ProposalExecuted(proposalId, approved, proposal.amount, proposal.recipient);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Deployment Script

The following deployment script will help deploy the `DAOTreasuryManagementContract` to the blockchain network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const DAOTreasuryManagementContract = await ethers.getContractFactory("DAOTreasuryManagementContract");

  // Replace this with your deployed ERC20 governance token contract address
  const governanceTokenAddress = "0xYourERC20TokenAddressHere";

  // Deploy the contract with the governance token address
  const daoTreasury = await DAOTreasuryManagementContract.deploy(governanceTokenAddress);

  await daoTreasury.deployed();

  console.log("DAOTreasuryManagementContract deployed to:", daoTreasury.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

The following test suite uses the Mocha framework with Chai assertions.

#### Test Script (`test/DAOTreasuryManagementContract.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAOTreasuryManagementContract", function () {
  let DAOTreasuryManagementContract;
  let daoTreasury;
  let GovernanceToken;
  let governanceToken;
  let owner;
  let voter1;
  let voter2;
  let recipient;

  beforeEach(async function () {
    [owner, voter1, voter2, recipient] = await ethers.getSigners();

    // Deploy a mock ERC20 governance token for testing purposes
    GovernanceToken = await ethers.getContractFactory("ERC20");
    governanceToken = await GovernanceToken.deploy("GovernanceToken", "GT");
    await governanceToken.deployed();

    // Distribute tokens to the voters
    await governanceToken.mint(voter1.address, ethers.utils.parseEther("100"));
    await governanceToken.mint(voter2.address, ethers.utils.parseEther("200"));

    // Deploy the DAOTreasuryManagementContract
    DAOTreasuryManagementContract = await ethers.getContractFactory("DAOTreasuryManagementContract");
    daoTreasury = await DAOTreasuryManagementContract.deploy(governanceToken.address);
    await daoTreasury.deployed();

    // Fund the DAO treasury with 10 ETH
    await owner.sendTransaction({ to: daoTreasury.address, value: ethers.utils.parseEther("10") });
  });

  it("Should create a proposal", async function () {
    await daoTreasury.createProposal("Proposal 1", "Fund development", ethers.utils.parseEther("1"), recipient.address);

    const proposal = await daoTreasury.proposals(0);
    expect(proposal.title).to.equal("Proposal 1");
    expect(proposal.amount).to.equal(ethers.utils.parseEther("1"));
  });

  it("Should allow voting with governance tokens", async function () {
    await daoTreasury.createProposal("Proposal 1", "Fund development", ethers.utils.parseEther("1"), recipient.address);

    await governanceToken.connect(voter1).approve(daoTreasury.address, ethers.utils.parseEther("100"));
    await daoTreasury.connect(voter1).vote(0, true);

    const proposal = await daoTreasury.proposals(0);
    expect(proposal.yesVotes).to.equal(ethers.utils.parseEther("100"));
  });

  it("Should execute a proposal when voting period is over", async function () {
    await daoTreasury.createProposal("Proposal 1", "Fund development", ethers.utils.parseEther("1"), recipient.address);

    await governanceToken.connect(voter1).approve(daoTreasury.address, ethers.utils.parseEther("100"));
    await daoTreasury.connect(voter1).vote(0, true);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await daoTreasury.executeProposal(0);

    const proposal = await daoTreasury.proposals(0);
    expect(proposal.executed).to.be.true;
    expect(await ethers.provider.getBalance(recipient.address)).to.equal(ethers.utils.parseEther("101"));
  });

  it("Should not allow voting after the voting period", async function () {
    await daoTreasury.createProposal("Proposal 1", "Fund development", ethers.utils.parseEther("1"), recipient.address);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await expect(daoTreasury.connect(voter1).vote(0, true)).to.be.revertedWith("Voting period has ended");
  });

  it("Should revert if the treasury does not have enough funds", async function () {
    await daoTreasury.createProposal("Proposal 1", "Fund development",

 ethers.utils.parseEther("20"), recipient.address);

    await governanceToken.connect(voter1).approve(daoTreasury.address, ethers.utils.parseEther("100"));
    await daoTreasury.connect(voter1).vote(0, true);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await expect(daoTreasury.executeProposal(0)).to.be.revertedWith("Insufficient treasury balance");
  });
});
```

### Running the Deployment and Tests

1. Deploy the contract:
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetworkName
   ```

2. Run the tests:
   ```bash
   npx hardhat test
   ```

This setup includes a complete deployment and testing framework for the `DAO Treasury Management Contract`. Adjust the deployment script with the appropriate ERC20 governance token address and network configuration as needed.