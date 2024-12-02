### Smart Contract: 3-1X_2A_DelegatedVotingContract.sol

#### Overview
This smart contract allows ERC777 token holders to delegate their voting power to another address (a proxy). It enables efficient governance by allowing trusted operators to vote on behalf of token holders, while still preserving individual influence. The contract supports advanced functionality offered by the ERC777 standard, including operator permissions.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DelegatedVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        uint256 totalVotedTokens;
        bool executed;
        uint256 deadline;
    }

    // ERC777 token used for voting
    IERC777 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Mapping for delegated voting
    mapping(address => address) public delegatedVotes;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Minimum quorum percentage (e.g., 20%)
    uint256 public quorumPercentage;

    // Event for proposal creation
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for delegation
    event Delegated(address indexed from, address indexed to);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId);

    // Constructor to initialize the contract with the ERC777 token, voting duration, and quorum percentage
    constructor(
        IERC777 _votingToken,
        uint256 _votingDuration,
        uint256 _quorumPercentage
    ) {
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        votingToken = _votingToken;
        votingDuration = _votingDuration;
        quorumPercentage = _quorumPercentage;
    }

    // Function to create a proposal
    function createProposal(string calldata _description) external onlyOwner {
        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            voteCount: 0,
            totalVotedTokens: 0,
            executed: false,
            deadline: block.timestamp + votingDuration
        });
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _description, proposals[proposalId].deadline);
    }

    // Function to vote on a proposal or to vote as a delegate
    function vote(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.voteCount += 1;
        proposal.totalVotedTokens += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to delegate voting power to another address
    function delegateVote(address _to) external nonReentrant {
        require(_to != address(0), "Cannot delegate to zero address");
        require(_to != msg.sender, "Cannot delegate to oneself");

        delegatedVotes[msg.sender] = _to;
        emit Delegated(msg.sender, _to);
    }

    // Function to vote on behalf of another address as a delegate
    function voteAsDelegate(uint256 _proposalId, address _from) external nonReentrant {
        require(delegatedVotes[_from] == msg.sender, "You are not a delegated voter for this address");
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][_from], "Already voted on behalf of this address");

        uint256 votePower = votingToken.balanceOf(_from);
        require(votePower > 0, "No voting power to delegate");

        proposal.voteCount += 1;
        proposal.totalVotedTokens += votePower;
        hasVoted[_proposalId][_from] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a proposal based on quorum and majority rules
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredQuorum = (totalSupply * quorumPercentage) / 100;

        // Check if the proposal has reached the required quorum
        bool quorumReached = proposal.totalVotedTokens >= requiredQuorum;

        // Execute the proposal if quorum is reached and majority is achieved
        if (quorumReached && (proposal.voteCount > (proposal.totalVotedTokens / 2))) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
            // Additional logic for proposal execution goes here (e.g., governance changes)
        }
    }

    // Function to get proposal details
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // Function to get total number of proposals
    function getProposalCount() external view returns (uint256) {
        return proposalCounter.current();
    }

    // Function to set a new voting duration
    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    // Function to set a new quorum percentage
    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyOwner {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        quorumPercentage = _newQuorumPercentage;
    }
}
```

### Contract Explanation

1. **Contract Type**: The contract is based on the ERC777 standard for advanced fungible tokens, enabling token holders to delegate their voting power to another address, known as a proxy. This allows for more flexible and efficient governance mechanisms.

2. **Core Functionalities**:
   - `createProposal`: Allows the contract owner to create new proposals with a description and a voting deadline.
   - `vote`: Allows token holders to vote on proposals with their own tokens.
   - `delegateVote`: Allows token holders to delegate their voting power to another address.
   - `voteAsDelegate`: Allows a delegate to vote on behalf of another address.
   - `executeProposal`: Allows the owner to execute a proposal after the voting period has ended, based on quorum and majority rules.

3. **Security Measures**:
   - **ReentrancyGuard**: Prevents reentrancy attacks.
   - **Ownable**: Restricts proposal creation and execution to the contract owner.
   - **HasVoted Mapping**: Ensures that each address can only vote once per proposal.
   - **DelegatedVotes Mapping**: Manages the delegation of voting power securely.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `Voted`: Emitted when a token holder votes on a proposal.
   - `Delegated`: Emitted when a token holder delegates their voting power to another address.
   - `ProposalExecuted`: Emitted when a proposal is successfully executed.

5. **Modifiers**:
   - `nonReentrant`: Ensures no reentrancy is possible during the `vote` and `delegateVote` functions.
   - `onlyOwner`: Restricts access to certain functions like creating and executing proposals.

### Deployment Instructions

1. **Deploy the Contract**:
   - Ensure you have the required `votingToken` address (ERC777 token contract address).
   - Specify the `votingDuration` in seconds (e.g., 1 week = 604800 seconds).
   - Specify the `quorumPercentage` (e.g., 20 for 20%).

2. **Deploy Script**:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       // Define contract variables
       const VotingTokenAddress = "<ERC777 Token Contract Address>";
       const VotingDuration = 604800; // 1 week in seconds
       const QuorumPercentage = 20; // 20% quorum

       // Get the contract factory and deploy
       const DelegatedVotingContract = await ethers.getContractFactory("DelegatedVotingContract");
       const delegatedVotingContract = await DelegatedVotingContract.deploy(VotingTokenAddress, VotingDuration, QuorumPercentage);

       // Wait for deployment to complete
       await delegatedVotingContract.deployed();

       console.log("DelegatedVotingContract deployed to:", delegatedVotingContract.address);
   }

   // Execute the script
   main()


       .then(() => process.exit(0))
       .catch((error) => {
           console.error(error);
           process.exit(1);
       });
   ```

3. **Verification & Testing**:
   - Create unit tests for the `createProposal`, `vote`, `delegateVote`, `voteAsDelegate`, and `executeProposal` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with the contract (creating proposals, voting, delegating, etc.).

5. **Additional Customizations**:
   - Implement more complex proposal execution logic (e.g., fund transfers or state changes).
   - Add features like dynamic quorum requirements or multi-phase voting periods.
   - Include a UI for easier interaction with the contract.

This smart contract is structured to offer a robust delegated voting mechanism using ERC777 tokens, incorporating industry standards and security best practices.