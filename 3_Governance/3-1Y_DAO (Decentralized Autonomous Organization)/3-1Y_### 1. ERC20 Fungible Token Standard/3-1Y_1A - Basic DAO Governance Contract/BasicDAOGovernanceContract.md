### Smart Contract: Basic DAO Governance Contract

Based on the provided requirements, I'll create a smart contract called `BasicDAOGovernanceContract.sol` using the ERC20 standard for tokenized voting power within a DAO (Decentralized Autonomous Organization).

#### Smart Contract Code (`BasicDAOGovernanceContract.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicDAOGovernanceContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    ERC20 public governanceToken;

    struct Proposal {
        string title;
        string description;
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
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId, bool approved);

    constructor(address _governanceToken) {
        governanceToken = ERC20(_governanceToken);
    }

    function createProposal(string memory title, string memory description) external onlyOwner whenNotPaused {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            title: title,
            description: description,
            endTime: block.timestamp + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, title, description, block.timestamp + VOTING_DURATION);
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
        emit ProposalExecuted(proposalId, approved);
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

The following deployment script will help deploy the `BasicDAOGovernanceContract` to the blockchain network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const BasicDAOGovernanceContract = await ethers.getContractFactory("BasicDAOGovernanceContract");

  // Replace this with your deployed ERC20 governance token contract address
  const governanceTokenAddress = "0xYourERC20TokenAddressHere";

  // Deploy the contract with the governance token address
  const daoGovernance = await BasicDAOGovernanceContract.deploy(governanceTokenAddress);

  await daoGovernance.deployed();

  console.log("BasicDAOGovernanceContract deployed to:", daoGovernance.address);
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

#### Test Script (`test/BasicDAOGovernanceContract.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BasicDAOGovernanceContract", function () {
  let BasicDAOGovernanceContract;
  let daoGovernance;
  let GovernanceToken;
  let governanceToken;
  let owner;
  let voter1;
  let voter2;

  beforeEach(async function () {
    [owner, voter1, voter2] = await ethers.getSigners();

    // Deploy a mock ERC20 governance token for testing purposes
    GovernanceToken = await ethers.getContractFactory("ERC20");
    governanceToken = await GovernanceToken.deploy("GovernanceToken", "GT");
    await governanceToken.deployed();

    // Distribute tokens to the voters
    await governanceToken.mint(voter1.address, ethers.utils.parseEther("100"));
    await governanceToken.mint(voter2.address, ethers.utils.parseEther("200"));

    // Deploy the BasicDAOGovernanceContract
    BasicDAOGovernanceContract = await ethers.getContractFactory("BasicDAOGovernanceContract");
    daoGovernance = await BasicDAOGovernanceContract.deploy(governanceToken.address);
    await daoGovernance.deployed();
  });

  it("Should create a proposal", async function () {
    await daoGovernance.createProposal("Proposal 1", "This is a test proposal");

    const proposal = await daoGovernance.proposals(0);
    expect(proposal.title).to.equal("Proposal 1");
  });

  it("Should allow voting with governance tokens", async function () {
    await daoGovernance.createProposal("Proposal 1", "This is a test proposal");

    await governanceToken.connect(voter1).approve(daoGovernance.address, ethers.utils.parseEther("100"));
    await daoGovernance.connect(voter1).vote(0, true);

    const proposal = await daoGovernance.proposals(0);
    expect(proposal.yesVotes).to.equal(ethers.utils.parseEther("100"));
  });

  it("Should execute a proposal when voting period is over", async function () {
    await daoGovernance.createProposal("Proposal 1", "This is a test proposal");

    await governanceToken.connect(voter1).approve(daoGovernance.address, ethers.utils.parseEther("100"));
    await daoGovernance.connect(voter1).vote(0, true);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await daoGovernance.executeProposal(0);

    const proposal = await daoGovernance.proposals(0);
    expect(proposal.executed).to.be.true;
  });

  it("Should not allow voting after the voting period", async function () {
    await daoGovernance.createProposal("Proposal 1", "This is a test proposal");

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await expect(daoGovernance.connect(voter1).vote(0, true)).to.be.revertedWith("Voting period has ended");
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

This setup includes a complete deployment and testing framework for the `Basic DAO Governance Contract`. Adjust the deployment script with the appropriate ERC20 governance token address and network configuration as needed.