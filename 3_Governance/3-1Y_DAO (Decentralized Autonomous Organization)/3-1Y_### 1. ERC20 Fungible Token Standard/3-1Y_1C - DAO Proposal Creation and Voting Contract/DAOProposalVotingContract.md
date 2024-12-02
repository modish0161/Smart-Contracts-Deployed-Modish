### Smart Contract: DAO Proposal Creation and Voting Contract

Based on your requirements, I will create a smart contract named `DAOProposalVotingContract.sol` using the ERC20 standard. This contract will allow token holders to create proposals for governance decisions and enable other token holders to vote on these proposals. The voting power will be proportional to the number of tokens held by each user, ensuring equitable governance within the DAO.

#### Smart Contract Code (`DAOProposalVotingContract.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DAOProposalVotingContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    ERC20 public governanceToken;
    uint256 public proposalFee;
    address public feeRecipient;

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

    event ProposalExecuted(
        uint256 indexed proposalId,
        bool approved
    );

    event ProposalFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);

    constructor(address _governanceToken, uint256 _proposalFee, address _feeRecipient) {
        require(_governanceToken != address(0), "Invalid token address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");

        governanceToken = ERC20(_governanceToken);
        proposalFee = _proposalFee;
        feeRecipient = _feeRecipient;
    }

    function createProposal(string memory title, string memory description) external nonReentrant whenNotPaused {
        require(governanceToken.balanceOf(msg.sender) > 0, "Must hold governance tokens to create proposal");
        require(governanceToken.transferFrom(msg.sender, feeRecipient, proposalFee), "Proposal fee transfer failed");

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

    function updateProposalFee(uint256 newFee) external onlyOwner {
        proposalFee = newFee;
        emit ProposalFeeUpdated(newFee);
    }

    function updateFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
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

The following deployment script will deploy the `DAOProposalVotingContract` to the blockchain network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const DAOProposalVotingContract = await ethers.getContractFactory("DAOProposalVotingContract");

  // Replace this with your deployed ERC20 governance token contract address
  const governanceTokenAddress = "0xYourERC20TokenAddressHere";
  const proposalFee = ethers.utils.parseEther("1"); // 1 ETH proposal fee
  const feeRecipient = "0xYourFeeRecipientAddressHere";

  // Deploy the contract with the governance token address, proposal fee, and fee recipient
  const daoProposalVoting = await DAOProposalVotingContract.deploy(governanceTokenAddress, proposalFee, feeRecipient);

  await daoProposalVoting.deployed();

  console.log("DAOProposalVotingContract deployed to:", daoProposalVoting.address);
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

#### Test Script (`test/DAOProposalVotingContract.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAOProposalVotingContract", function () {
  let DAOProposalVotingContract;
  let daoProposalVoting;
  let GovernanceToken;
  let governanceToken;
  let owner;
  let voter1;
  let voter2;
  let feeRecipient;

  beforeEach(async function () {
    [owner, voter1, voter2, feeRecipient] = await ethers.getSigners();

    // Deploy a mock ERC20 governance token for testing purposes
    GovernanceToken = await ethers.getContractFactory("ERC20");
    governanceToken = await GovernanceToken.deploy("GovernanceToken", "GT");
    await governanceToken.deployed();

    // Distribute tokens to the voters
    await governanceToken.mint(voter1.address, ethers.utils.parseEther("100"));
    await governanceToken.mint(voter2.address, ethers.utils.parseEther("200"));

    // Deploy the DAOProposalVotingContract
    DAOProposalVotingContract = await ethers.getContractFactory("DAOProposalVotingContract");
    daoProposalVoting = await DAOProposalVotingContract.deploy(governanceToken.address, ethers.utils.parseEther("1"), feeRecipient.address);
    await daoProposalVoting.deployed();
  });

  it("Should create a proposal with the correct fee", async function () {
    await governanceToken.connect(voter1).approve(daoProposalVoting.address, ethers.utils.parseEther("1"));
    await daoProposalVoting.connect(voter1).createProposal("Proposal 1", "Improve governance");

    const proposal = await daoProposalVoting.proposals(0);
    expect(proposal.title).to.equal("Proposal 1");

    const feeRecipientBalance = await governanceToken.balanceOf(feeRecipient.address);
    expect(feeRecipientBalance).to.equal(ethers.utils.parseEther("1"));
  });

  it("Should allow voting with governance tokens", async function () {
    await governanceToken.connect(voter1).approve(daoProposalVoting.address, ethers.utils.parseEther("1"));
    await daoProposalVoting.connect(voter1).createProposal("Proposal 1", "Improve governance");

    await daoProposalVoting.connect(voter2).vote(0, true);

    const proposal = await daoProposalVoting.proposals(0);
    expect(proposal.yesVotes).to.equal(ethers.utils.parseEther("200"));
  });

  it("Should execute a proposal when voting period is over", async function () {
    await governanceToken.connect(voter1).approve(daoProposalVoting.address, ethers.utils.parseEther("1"));
    await daoProposalVoting.connect(voter1).createProposal("Proposal 1", "Improve governance");

    await daoProposalVoting.connect(voter2).vote(0, true);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await daoProposalVoting.executeProposal(0);

    const proposal = await daoProposalVoting.proposals(0);
    expect(proposal.executed).to.be.true;
  });

  it("Should not allow voting after the voting period", async function () {
    await governanceToken.connect(voter1).approve(daoProposalVoting.address, ethers.utils.parseEther("1"));
    await daoProposalVoting.connect(voter1).createProposal("Proposal 1", "Improve governance");

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 

60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await expect(daoProposalVoting.connect(voter2).vote(0, true)).to.be.revertedWith("Voting period has ended");
  });
});
```

### Running the Deployment and Tests

1. **Deploy the contract:**
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetworkName
   ```

2. **Run the tests:**
   ```bash
   npx hardhat test
   ```

This setup includes a complete smart contract, deployment, and testing framework for the `DAO Proposal Creation and Voting Contract`. Adjust the deployment script with the appropriate ERC20 governance token address and network configuration as needed.