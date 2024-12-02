### Smart Contract: Accredited Voting Contract with AnonCreds

Based on the provided requirements, I'll create a smart contract called `AccreditedVotingContractWithAnonCreds.sol` using the AnonCreds standard for privacy-preserving credentials. This contract will allow only accredited investors or verified participants to vote on governance decisions while ensuring that their identities and personal details remain confidential.

#### Smart Contract Code (`AccreditedVotingContractWithAnonCreds.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for AnonCreds-based identity verification and privacy-preserving voting
interface IAnonCreds {
    function verifyProof(bytes memory proof, bytes32[] memory merkleProof, bytes32 root) external view returns (bool);
    function getRootHash() external view returns (bytes32);
}

contract AccreditedVotingContractWithAnonCreds is Ownable, ReentrancyGuard, Pausable {
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
    }

    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;

    uint256 public constant VOTING_PERIOD = 7 days;
    bytes32 public rootHash;

    IAnonCreds public anonCredsVerifier;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorum,
        uint256 approvalPercentage,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _anonCredsVerifier) {
        anonCredsVerifier = IAnonCreds(_anonCredsVerifier);
    }

    function setRootHash(bytes32 _rootHash) external onlyOwner {
        rootHash = _rootHash;
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 quorum,
        uint256 approvalPercentage
    ) external onlyOwner whenNotPaused {
        require(quorum > 0 && quorum <= 100, "Invalid quorum percentage");
        require(approvalPercentage > 0 && approvalPercentage <= 100, "Invalid approval percentage");

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
            endTime: block.timestamp + VOTING_PERIOD
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

    function vote(uint256 proposalId, bool support, bytes memory proof, bytes32[] memory merkleProof)
        external
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended");

        bytes32 leaf = keccak256(proof);
        require(!hasVoted[proposalId][leaf], "Already voted");

        // Verify the zero-knowledge proof
        require(anonCredsVerifier.verifyProof(proof, merkleProof, rootHash), "Invalid proof");

        // Assume the weight of the vote is 1, as privacy-preserving proofs do not reveal vote weight
        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(1);
        } else {
            proposal.noVotes = proposal.noVotes.add(1);
        }

        hasVoted[proposalId][leaf] = true;

        emit VoteCasted(proposalId, support, 1);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 quorumVotes = totalVotes.mul(proposal.quorum).div(100);
        uint256 approvalVotes = proposal.yesVotes.mul(100).div(totalVotes);

        require(totalVotes >= quorumVotes, "Quorum not reached");
        require(approvalVotes >= proposal.approvalPercentage, "Approval percentage not reached");

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

The following deployment script will help deploy the `AccreditedVotingContractWithAnonCreds` to the blockchain network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const AccreditedVotingContractWithAnonCreds = await ethers.getContractFactory("AccreditedVotingContractWithAnonCreds");

  // Replace this with the deployed AnonCreds verifier contract address
  const anonCredsVerifierAddress = "0xYourAnonCredsVerifierAddressHere";

  // Deploy the contract with the AnonCreds verifier address
  const accreditedVoting = await AccreditedVotingContractWithAnonCreds.deploy(anonCredsVerifierAddress);

  await accreditedVoting.deployed();

  console.log("AccreditedVotingContractWithAnonCreds deployed to:", accreditedVoting.address);
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

#### Test Script (`test/AccreditedVotingContractWithAnonCreds.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AccreditedVotingContractWithAnonCreds", function () {
  let AccreditedVotingContractWithAnonCreds;
  let accreditedVoting;
  let AnonCredsVerifierMock;
  let anonCredsVerifier;
  let owner;
  let voter1;
  let voter2;

  beforeEach(async function () {
    [owner, voter1, voter2] = await ethers.getSigners();

    // Deploy a mock AnonCreds verifier for testing purposes
    AnonCredsVerifierMock = await ethers.getContractFactory("AnonCredsVerifierMock");
    anonCredsVerifier = await AnonCredsVerifierMock.deploy();
    await anonCredsVerifier.deployed();

    // Deploy the AccreditedVotingContractWithAnonCreds
    AccreditedVotingContractWithAnonCreds = await ethers.getContractFactory("AccreditedVotingContractWithAnonCreds");
    accreditedVoting = await AccreditedVotingContractWithAnonCreds.deploy(anonCredsVerifier.address);
    await accreditedVoting.deployed();

    // Set a root hash for testing
    const rootHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("rootHash"));
    await accreditedVoting.setRootHash(rootHash);
  });

  it("Should create a proposal", async function () {
    await accreditedVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50, // Quorum
      50 // Approval percentage
    );

    const proposal = await accreditedVoting.proposals(0);
    expect(proposal.title).to.equal("Proposal 1");
  });

  it("Should allow voting with a valid proof", async function () {
    await accreditedVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50
    );

    const validProof = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("validProof"));
    const merkleProof = [ethers.utils.keccak256(ethers.utils.toUtf8Bytes("rootHash"))];

    await accreditedVoting.connect(voter1).vote(0, true, validProof, merkleProof);

    const proposal = await accreditedVoting.proposals(0);
    expect(proposal.yesVotes).to.equal(1);
  });

  it("Should reject voting with an invalid proof", async function () {
    await accreditedVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50
    );

    const invalidProof = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("invalidProof"));
    const merkleProof = [ethers.utils.keccak256(ethers.utils.toUtf8Bytes("rootHash"))];

    await expect(accreditedVoting.connect(voter1).vote(0, true, invalidProof, merkleProof)).to.be.revertedWith("Invalid proof");
  });

  it("Should execute a proposal when quorum and approval are met", async function () {
    await accreditedVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50
    );

    const validProof = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("validProof"));
    const merkleProof = [ethers.utils.keccak256(ethers.utils.toUtf8

Bytes("rootHash"))];

    await accreditedVoting.connect(voter1).vote(0, true, validProof, merkleProof);
    await accreditedVoting.connect(voter2).vote(0, true, validProof, merkleProof);

    // Wait for the voting period to end (7 days) in the test scenario
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await accreditedVoting.executeProposal(0);

    const proposal = await accreditedVoting.proposals(0);
    expect(proposal.executed).to.be.true;
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

This setup includes a complete deployment and testing framework for the `Accredited Voting Contract with AnonCreds`. Adjust the deployment script with the appropriate AnonCreds verifier address and network configuration as needed.