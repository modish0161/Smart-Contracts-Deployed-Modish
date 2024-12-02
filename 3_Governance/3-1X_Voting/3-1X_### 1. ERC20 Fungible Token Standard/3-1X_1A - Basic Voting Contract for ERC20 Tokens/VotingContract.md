### Smart Contract: 3-1X_1A_VotingContract.sol

#### Overview
This smart contract is designed to enable ERC20 token holders to vote on key governance decisions with voting power proportional to the number of tokens they own. This contract is suitable for use in decentralized autonomous organizations (DAOs) or investment platforms, where stakeholders need to have influence over governance matters.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string description;
        uint256 voteCount;
        bool executed;
        uint256 deadline;
    }

    // ERC20 token used for voting
    IERC20 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Event for proposal creation
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    
    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);
    
    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId);

    // Constructor to initialize the contract with the ERC20 token and voting duration
    constructor(IERC20 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a proposal
    function createProposal(string calldata _description) external onlyOwner {
        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            voteCount: 0,
            executed: false,
            deadline: block.timestamp + votingDuration
        });
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _description, proposals[proposalId].deadline);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.voteCount += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a proposal (can be customized for more logic)
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        // Example logic for execution (customize as needed)
        if (proposal.voteCount > (votingToken.totalSupply() / 2)) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
            // Additional logic for proposal execution goes here
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
}
```

### Contract Explanation

1. **Contract Type**: The contract is based on the ERC20 standard for voting power. It allows token holders to vote on proposals where voting power is proportional to the number of tokens held.

2. **Core Functionalities**:
   - `createProposal`: Allows the contract owner to create new proposals with a description and a voting deadline.
   - `vote`: Allows token holders to vote on proposals. Voting power is determined by the token balance of the voter.
   - `executeProposal`: Allows the owner to execute a proposal after the voting period has ended and certain conditions are met (e.g., majority vote).

3. **Security Measures**:
   - **ReentrancyGuard**: Prevents reentrancy attacks.
   - **Ownable**: Restricts proposal creation and execution to the contract owner.
   - **HasVoted Mapping**: Ensures that each address can only vote once per proposal.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `Voted`: Emitted when a token holder votes on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is successfully executed.

5. **Modifiers**:
   - `nonReentrant`: Ensures no reentrancy is possible during the `vote` function.
   - `onlyOwner`: Restricts access to certain functions like creating and executing proposals.

### Deployment Instructions

1. **Deploy the Contract**:
   - Ensure you have the required `votingToken` address (ERC20 token contract address).
   - Specify the `votingDuration` in seconds (e.g., 1 week = 604800 seconds).

2. **Deploy Script**:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       // Define contract variables
       const VotingTokenAddress = "<ERC20 Token Contract Address>";
       const VotingDuration = 604800; // 1 week in seconds

       // Get the contract factory and deploy
       const VotingContract = await ethers.getContractFactory("VotingContract");
       const votingContract = await VotingContract.deploy(VotingTokenAddress, VotingDuration);

       // Wait for deployment to complete
       await votingContract.deployed();

       console.log("VotingContract deployed to:", votingContract.address);
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
   - Create unit tests for the `createProposal`, `vote`, and `executeProposal` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with the contract (creating proposals, voting, etc.).

5. **Additional Customizations**:
   - Implement more complex proposal execution logic (e.g., fund transfers or state changes).
   - Add features like quorum requirements or multiple voting periods.
   - Include a UI for easier interaction with the contract.

This smart contract is structured to offer a robust voting mechanism using ERC20 tokens, incorporating industry standards and security best practices.