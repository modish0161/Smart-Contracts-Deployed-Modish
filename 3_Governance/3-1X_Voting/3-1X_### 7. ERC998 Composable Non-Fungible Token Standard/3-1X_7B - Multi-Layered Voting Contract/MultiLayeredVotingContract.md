### Smart Contract: Multi-Layered Voting Contract

Let's begin by creating the smart contract based on the provided specifications for the Multi-Layered Voting Contract using the ERC998 standard. This contract will allow composable token holders to vote on decisions that affect both the parent token and the underlying assets.

#### Smart Contract Code (`MultiLayeredVotingContract.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiLayeredVotingContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Proposal {
        string title;
        string description;
        uint256 quorum;
        uint256 approvalPercentage;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        uint256 endTime;
        address[] affectedAssets;
        bytes[] executionData;
    }

    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public whitelist;

    uint256 public constant VOTING_PERIOD = 7 days;

    ERC721Enumerable public erc998Token;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorum,
        uint256 approvalPercentage,
        uint256 endTime
    );

    event VoteCasted(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "You are not authorized to vote");
        _;
    }

    constructor(address _erc998Token) {
        erc998Token = ERC721Enumerable(_erc998Token);
    }

    function addWhitelist(address voter) external onlyOwner {
        whitelist[voter] = true;
    }

    function removeWhitelist(address voter) external onlyOwner {
        whitelist[voter] = false;
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 quorum,
        uint256 approvalPercentage,
        address[] memory affectedAssets,
        bytes[] memory executionData
    ) external onlyOwner whenNotPaused {
        require(quorum > 0 && quorum <= 100, "Invalid quorum percentage");
        require(
            approvalPercentage > 0 && approvalPercentage <= 100,
            "Invalid approval percentage"
        );
        require(
            affectedAssets.length == executionData.length,
            "Mismatched assets and data"
        );

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            title: title,
            description: description,
            quorum: quorum,
            approvalPercentage: approvalPercentage,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            endTime: block.timestamp + VOTING_PERIOD,
            affectedAssets: affectedAssets,
            executionData: executionData
        });

        emit ProposalCreated(
            proposalId,
            title,
            description,
            quorum,
            approvalPercentage,
            block.timestamp + VOTING_PERIOD
        );
    }

    function vote(uint256 proposalId, bool support)
        external
        onlyWhitelisted
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp < proposal.endTime,
            "Voting period has ended"
        );
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = erc998Token.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(weight);
        } else {
            proposal.noVotes = proposal.noVotes.add(weight);
        }

        hasVoted[proposalId][msg.sender] = true;

        emit VoteCasted(msg.sender, proposalId, support, weight);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 quorumVotes = erc998Token.totalSupply().mul(proposal.quorum).div(100);
        uint256 approvalVotes = proposal.yesVotes.mul(100).div(totalVotes);

        require(totalVotes >= quorumVotes, "Quorum not reached");
        require(approvalVotes >= proposal.approvalPercentage, "Approval percentage not reached");

        for (uint256 i = 0; i < proposal.affectedAssets.length; i++) {
            (bool success, ) = proposal.affectedAssets[i].call(
                proposal.executionData[i]
            );
            require(success, "Execution failed for asset");
        }

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
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

The following deployment script will help deploy the `MultiLayeredVotingContract` to the blockchain network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const MultiLayeredVotingContract = await ethers.getContractFactory("MultiLayeredVotingContract");

  // Replace this with the deployed ERC998 contract address
  const erc998TokenAddress = "0xYourERC998TokenAddressHere";

  // Deploy the contract with the ERC998 token address
  const multiLayeredVoting = await MultiLayeredVotingContract.deploy(erc998TokenAddress);

  await multiLayeredVoting.deployed();

  console.log("MultiLayeredVotingContract deployed to:", multiLayeredVoting.address);
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

#### Test Script (`test/MultiLayeredVotingContract.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiLayeredVotingContract", function () {
  let MultiLayeredVotingContract;
  let multiLayeredVoting;
  let ERC998Mock;
  let erc998Token;
  let owner;
  let voter1;
  let voter2;
  let voter3;

  beforeEach(async function () {
    [owner, voter1, voter2, voter3] = await ethers.getSigners();

    // Deploy a mock ERC998 contract for testing purposes
    ERC998Mock = await ethers.getContractFactory("ERC721Enumerable"); // Use ERC721Enumerable for testing
    erc998Token = await ERC998Mock.deploy("MockComposableToken", "MCT");
    await erc998Token.deployed();

    // Mint some composable tokens to voters
    await erc998Token.mint(voter1.address, 1);
    await erc998Token.mint(voter2.address, 2);
    await erc998Token.mint(voter3.address, 3);

    // Deploy the MultiLayeredVotingContract
    MultiLayeredVotingContract = await ethers.getContractFactory("MultiLayeredVotingContract");
    multiLayeredVoting = await MultiLayeredVotingContract.deploy(erc998Token.address);
    await multiLayeredVoting.deployed();
  });

  it("Should add voters to the whitelist", async function () {
    await multiLayeredVoting.addWhitelist(voter1.address);
    await multiLayeredVoting.addWhitelist(voter2.address);
    expect(await multiLayeredVoting.whitelist(voter1.address)).to.be.true;
    expect(await multiLayeredVoting.whitelist(voter2.address)).to.be.true;
  });

  it("Should create a proposal", async function () {
    await multiLayeredVoting.addWhitelist(voter1.address);
    await multiLayeredVoting.addWhitelist(voter2.address);
    await multiLayeredVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50, // Quorum
      50, // Approval percentage
      [erc998Token.address], // Affected assets
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])] // Execution data
    );

    const proposal = await multiLayeredVoting.proposals(0);
    expect(proposal.title).to.equal("Proposal 1");
  });

  it("Should allow whitelisted voters to vote", async function () {
    await multiLayeredVoting.addWhitelist(voter1.address);
    await multiLayeredVoting.addWhitelist(voter2.address);

    await multiLayeredVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await multiLayeredVoting.connect(voter1).vote(0, true); // Vote Yes
    await multiLayeredVoting.connect(voter2).vote(0, false); // Vote No

    const proposal

 = await multiLayeredVoting.proposals(0);
    expect(proposal.yesVotes).to.equal(1);
    expect(proposal.noVotes).to.equal(1);
  });

  it("Should execute a proposal when quorum and approval are met", async function () {
    await multiLayeredVoting.addWhitelist(voter1.address);
    await multiLayeredVoting.addWhitelist(voter2.address);
    await multiLayeredVoting.addWhitelist(voter3.address);

    await multiLayeredVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await multiLayeredVoting.connect(voter1).vote(0, true); // Vote Yes
    await multiLayeredVoting.connect(voter2).vote(0, true); // Vote Yes

    // Wait for the voting period to end (7 days) in test scenario, we simulate time passing
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await multiLayeredVoting.executeProposal(0);

    const proposal = await multiLayeredVoting.proposals(0);
    expect(proposal.executed).to.be.true;
  });

  it("Should not allow non-whitelisted addresses to vote", async function () {
    await multiLayeredVoting.addWhitelist(voter1.address);
    await multiLayeredVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await expect(multiLayeredVoting.connect(voter2).vote(0, true)).to.be.revertedWith("You are not authorized to vote");
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

Replace `yourNetworkName` with the network you have configured in `hardhat.config.js`.

This setup includes a complete deployment and testing framework for the Multi-Layered Voting Contract. Further customization and optimization can be done based on specific use cases.