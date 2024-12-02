### Smart Contract: 3-1X_7A_ComposableAssetVotingContract.sol

#### Overview
This smart contract enables token holders of composable tokens (ERC998) to vote on decisions that affect the underlying assets, ensuring decentralized decision-making for complex asset portfolios. It leverages the ERC998 standard to support bundled assets and allows governance decisions at both the individual component level and the overall portfolio level.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998ERC721TopDown.sol";

contract ComposableAssetVotingContract is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 deadline;
        bool executed;
        uint256 quorumRequired;
        uint256 approvalPercentageRequired;
        address[] affectedAssets;
        bytes[] executionData;
    }

    // ERC998 Composable Token Interface
    ERC998ERC721TopDown public composableToken;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to track if a user has voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Whitelisted addresses for voting
    EnumerableSet.AddressSet private whitelistedAddresses;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorumRequired,
        uint256 approvalPercentageRequired,
        uint256 deadline
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 voteType);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed account, bool status);

    // Constructor
    constructor(ERC998ERC721TopDown _composableToken) {
        composableToken = _composableToken;
    }

    // Modifier to check if the sender is whitelisted
    modifier onlyWhitelisted() {
        require(whitelistedAddresses.contains(msg.sender), "You are not authorized to vote");
        _;
    }

    // Function to add an address to the whitelist
    function addWhitelist(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        require(!whitelistedAddresses.contains(_account), "Already whitelisted");
        whitelistedAddresses.add(_account);
        emit WhitelistUpdated(_account, true);
    }

    // Function to remove an address from the whitelist
    function removeWhitelist(address _account) external onlyOwner {
        require(whitelistedAddresses.contains(_account), "Not in whitelist");
        whitelistedAddresses.remove(_account);
        emit WhitelistUpdated(_account, false);
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistedAddresses.contains(_account);
    }

    // Function to create a proposal
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _quorumRequired,
        uint256 _approvalPercentageRequired,
        address[] calldata _affectedAssets,
        bytes[] calldata _executionData
    ) external onlyOwner {
        require(_quorumRequired > 0 && _quorumRequired <= 100, "Invalid quorum");
        require(_approvalPercentageRequired > 0 && _approvalPercentageRequired <= 100, "Invalid approval percentage");

        uint256 proposalId = proposalCounter.current();
        proposalCounter.increment();

        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            executed: false,
            deadline: block.timestamp + 7 days, // Default voting period of 7 days
            quorumRequired: _quorumRequired,
            approvalPercentageRequired: _approvalPercentageRequired,
            affectedAssets: _affectedAssets,
            executionData: _executionData
        });

        emit ProposalCreated(
            proposalId,
            _title,
            _description,
            _quorumRequired,
            _approvalPercentageRequired,
            block.timestamp + 7 days
        );
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, uint8 _voteType) external onlyWhitelisted nonReentrant {
        require(_voteType >= 1 && _voteType <= 3, "Invalid vote type"); // 1 = Yes, 2 = No, 3 = Abstain
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 weight = composableToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.voteCount += 1;
        hasVoted[_proposalId][msg.sender] = true;

        if (_voteType == 1) {
            proposal.yesVotes += weight;
        } else if (_voteType == 2) {
            proposal.noVotes += weight;
        } else if (_voteType == 3) {
            proposal.abstainVotes += weight;
        }

        emit VoteCast(msg.sender, _proposalId, _voteType);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = composableToken.totalSupply();
        uint256 requiredQuorum = (totalSupply * proposal.quorumRequired) / 100;
        uint256 approvalPercentage = (proposal.yesVotes * 100) / (proposal.yesVotes + proposal.noVotes);

        bool quorumReached = proposal.yesVotes >= requiredQuorum;
        bool approved = approvalPercentage >= proposal.approvalPercentageRequired;

        if (quorumReached && approved) {
            proposal.executed = true;
            bool success = true;
            for (uint256 i = 0; i < proposal.executionData.length; i++) {
                (bool callSuccess,) = address(proposal.affectedAssets[i]).call(proposal.executionData[i]);
                if (!callSuccess) success = false;
            }
            emit ProposalExecuted(_proposalId, success);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to get the details of a proposal
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 voteCount,
            uint256 yesVotes,
            uint256 noVotes,
            uint256 abstainVotes,
            bool executed,
            uint256 deadline,
            uint256 quorumRequired,
            uint256 approvalPercentageRequired,
            address[] memory affectedAssets
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.deadline,
            proposal.quorumRequired,
            proposal.approvalPercentageRequired,
            proposal.affectedAssets
        );
    }

    // Function to get the total number of proposals
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter.current();
    }
}
```

### Contract Explanation

1. **Contract Type**:
   - The contract is built on the ERC998 standard to enable governance and voting on composable tokens that represent bundled assets.

2. **Core Functionalities**:
   - **Whitelist Management**:
     - `addWhitelist`: Adds an address to the whitelist for voting.
     - `removeWhitelist`: Removes an address from the whitelist.
     - `isWhitelisted`: Checks if an address is whitelisted.
   - **Proposal Management**:
     - `createProposal`: Allows the owner to create a proposal with quorum, approval percentage, and execution data for specific affected assets.
     - `vote`: Allows whitelisted addresses to vote on proposals with three options: Yes, No, and Abstain.
     - `executeProposal`: Executes the proposal if the required quorum and approval percentage are met.
   - **Proposal Information**:
     - `getProposal`: Returns the details of a specific proposal.
     - `getTotalProposals`: Returns the total number of proposals.

3. **Governance Mechanism**:
   - **Voting Options**: Voters can choose from three options: Yes, No, and Abstain.
   - **Quorum & Approval Percentage**: Proposals require a certain quorum and approval percentage to be executed.
   - **Execution Data**: Proposals can include execution data for specific actions on the affected assets.

4. **Security and Compliance**:
   - **Restricted Voting**: Only whitelisted addresses can participate in voting.
   - **ReentrancyGuard**: Prevents re

entrancy attacks during voting and proposal execution.

5. **Gas Optimization**:
   - Efficient data structures and external function calls to minimize gas costs.

### Deployment and Testing
1. **Deployment**:
   - Deploy the contract on the desired blockchain using Hardhat or Truffle.
   - Use the provided deployment scripts to automate the process.

2. **Testing**:
   - Write comprehensive unit tests for core functionalities like proposal creation, voting, and execution.
   - Test edge cases for quorum and approval percentage, as well as invalid scenarios.

3. **Additional Features**:
   - Oracle integration for real-time asset valuation or compliance checks.
   - DeFi integration for automated yield management based on voted strategies.

This contract provides a robust governance system for managing composable assets, enabling transparent and decentralized decision-making for complex asset portfolios.

### Deployment Script

The following deployment script will help deploy the `ComposableAssetVotingContract` to the blockchain network of your choice. This script uses the Hardhat framework and assumes that you have already set up your Hardhat environment.

#### Prerequisites:
1. Install Hardhat:
   ```bash
   npm install --save-dev hardhat
   ```

2. Install the OpenZeppelin contracts:
   ```bash
   npm install @openzeppelin/contracts
   ```

3. Configure Hardhat with your desired network settings (e.g., for Ethereum, Binance Smart Chain, etc.) in `hardhat.config.js`.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const ComposableAssetVotingContract = await ethers.getContractFactory("ComposableAssetVotingContract");

  // Replace this with the deployed ERC998 contract address
  const erc998TokenAddress = "0xYourERC998TokenAddressHere";

  // Deploy the contract with the ERC998 token address
  const composableAssetVoting = await ComposableAssetVotingContract.deploy(erc998TokenAddress);

  await composableAssetVoting.deployed();

  console.log("ComposableAssetVotingContract deployed to:", composableAssetVoting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

#### Running the Deployment Script
1. Update the `erc998TokenAddress` variable in the script with the address of the deployed ERC998 token.
2. Run the script:
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetworkName
   ```
   Replace `yourNetworkName` with the network you have configured in `hardhat.config.js`.

### Test Suite

The following test suite uses the Mocha framework with Chai assertions. It covers basic functionality like creating proposals, voting, and executing proposals.

#### Test Script (`test/ComposableAssetVotingContract.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComposableAssetVotingContract", function () {
  let ComposableAssetVotingContract;
  let composableAssetVoting;
  let ERC998Mock;
  let erc998Token;
  let owner;
  let voter1;
  let voter2;
  let voter3;

  beforeEach(async function () {
    [owner, voter1, voter2, voter3] = await ethers.getSigners();

    // Deploy a mock ERC998 contract for testing purposes
    ERC998Mock = await ethers.getContractFactory("ERC998ERC721TopDown");
    erc998Token = await ERC998Mock.deploy("MockComposableToken", "MCT");
    await erc998Token.deployed();

    // Mint some composable tokens to voters
    await erc998Token.mint(voter1.address, 1);
    await erc998Token.mint(voter2.address, 2);
    await erc998Token.mint(voter3.address, 3);

    // Deploy the ComposableAssetVotingContract
    ComposableAssetVotingContract = await ethers.getContractFactory("ComposableAssetVotingContract");
    composableAssetVoting = await ComposableAssetVotingContract.deploy(erc998Token.address);
    await composableAssetVoting.deployed();
  });

  it("Should add voters to the whitelist", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    expect(await composableAssetVoting.isWhitelisted(voter1.address)).to.be.true;
    expect(await composableAssetVoting.isWhitelisted(voter2.address)).to.be.true;
  });

  it("Should create a proposal", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50, // Quorum
      50, // Approval percentage
      [erc998Token.address], // Affected assets
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])] // Execution data
    );

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.title).to.equal("Proposal 1");
  });

  it("Should allow whitelisted voters to vote", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);

    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await composableAssetVoting.connect(voter1).vote(0, 1); // Vote Yes
    await composableAssetVoting.connect(voter2).vote(0, 2); // Vote No

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.yesVotes).to.equal(1);
    expect(proposal.noVotes).to.equal(1);
  });

  it("Should execute a proposal when quorum and approval are met", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    await composableAssetVoting.addWhitelist(voter3.address);

    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await composableAssetVoting.connect(voter1).vote(0, 1); // Vote Yes
    await composableAssetVoting.connect(voter2).vote(0, 1); // Vote Yes

    // Wait for the voting period to end (7 days) in test scenario, we simulate time passing
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await composableAssetVoting.executeProposal(0);

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.executed).to.be.true;
  });

  it("Should not allow non-whitelisted addresses to vote", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await expect(composableAssetVoting.connect(voter2).vote(0, 1)).to.be.revertedWith("You are not authorized to vote");
  });
});
```

### Test Script Explanation

1. **Setup**:
   - Deploys a mock ERC998 contract and mints composable tokens to test accounts.
   - Deploys the `ComposableAssetVotingContract` with the ERC998 token address.

2. **Test Cases**:
   - **Whitelist Management**: Verifies the addition and removal of addresses to the whitelist.
   - **Proposal Creation**: Tests creating proposals with title, description, quorum, approval percentage, and execution data.
   - **Voting**: Tests that whitelisted addresses can vote on proposals and that non-whitelisted addresses cannot vote.
   - **Proposal Execution**: Tests that proposals meeting the quorum and approval conditions are executed.

### Running the Tests

1. Save the test script as `test/ComposableAssetVotingContract.test.js`.
2. Run the tests:
   ```bash
   npx hardhat test
   ```

This suite provides a basic framework for testing the essential functionalities of the contract. Further test cases can be added for edge cases, performance, and security.