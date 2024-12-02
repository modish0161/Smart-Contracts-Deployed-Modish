### Smart Contract: 3-1X_4B_CorporateGovernanceVotingContract.sol

#### Overview
This smart contract enables shareholders represented by ERC1400 security tokens to vote on corporate governance changes, such as amendments to bylaws or strategic direction. Voting power is proportional to the number of security tokens held, ensuring that stakeholder influence is aligned with ownership.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CorporateGovernanceVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 totalVotes;
        uint256 totalTokensVoted;
        bool executed;
        uint256 deadline;
        uint256 requiredQuorum;
        uint256 approvalPercentage;
    }

    // ERC1400 security token used for voting
    IERC1400 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Event for proposal creation
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 requiredQuorum,
        uint256 approvalPercentage,
        uint256 deadline
    );

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Constructor to initialize the contract with the ERC1400 token, voting duration, and default quorum
    constructor(IERC1400 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a proposal with a specified quorum and approval percentage
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requiredQuorum,
        uint256 _approvalPercentage
    ) external onlyOwner {
        require(_requiredQuorum > 0 && _requiredQuorum <= 100, "Quorum must be between 1 and 100");
        require(_approvalPercentage > 0 && _approvalPercentage <= 100, "Approval percentage must be between 1 and 100");

        uint256 proposalId = proposalCounter.current();
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.title = _title;
        proposal.description = _description;
        proposal.totalVotes = 0;
        proposal.totalTokensVoted = 0;
        proposal.executed = false;
        proposal.deadline = block.timestamp + votingDuration;
        proposal.requiredQuorum = _requiredQuorum;
        proposal.approvalPercentage = _approvalPercentage;
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, _requiredQuorum, _approvalPercentage, proposal.deadline);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.totalVotes += 1;
        proposal.totalTokensVoted += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a proposal based on quorum and approval percentage rules
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredTokens = (totalSupply * proposal.requiredQuorum) / 100;

        // Check if the proposal has reached the required quorum
        bool quorumReached = proposal.totalTokensVoted >= requiredTokens;

        // Calculate approval percentage
        uint256 approval = (proposal.totalTokensVoted * 100) / totalSupply;

        // Execute the proposal if quorum is reached and approval percentage is met
        if (quorumReached && approval >= proposal.approvalPercentage) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
            // Additional logic for proposal execution goes here (e.g., governance changes)
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to get proposal details
    function getProposal(uint256 _proposalId) external view returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 totalVotes,
        uint256 totalTokensVoted,
        bool executed,
        uint256 deadline,
        uint256 requiredQuorum,
        uint256 approvalPercentage
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.totalVotes,
            proposal.totalTokensVoted,
            proposal.executed,
            proposal.deadline,
            proposal.requiredQuorum,
            proposal.approvalPercentage
        );
    }

    // Function to get total number of proposals
    function getProposalCount() external view returns (uint256) {
        return proposalCounter.current();
    }

    // Function to set a new voting duration
    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    // Function to check if a user has voted on a specific proposal
    function hasUserVoted(uint256 _proposalId, address _user) external view returns (bool) {
        return hasVoted[_proposalId][_user];
    }
}
```

### Contract Explanation

1. **Contract Type**: The contract uses the ERC1400 security token standard and enables corporate governance voting. It allows shareholders represented by ERC1400 tokens to vote on corporate governance changes, ensuring that influence is proportional to ownership.

2. **Core Functionalities**:
   - `createProposal`: Allows the contract owner to create a new proposal with a title, description, quorum requirement, and approval percentage.
   - `vote`: Allows token holders to vote on proposals. Voting power is determined by the token balance of the voter.
   - `executeProposal`: Allows the owner to execute a proposal after the voting period has ended, based on quorum and approval percentage rules.

3. **Security Measures**:
   - **ReentrancyGuard**: Prevents reentrancy attacks.
   - **Ownable**: Restricts proposal creation and execution to the contract owner.
   - **HasVoted Mapping**: Ensures that each address can only vote once per proposal.
   - **Quorum and Approval Check**: Ensures that a proposal can only be executed if it reaches the required quorum and approval percentage.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `Voted`: Emitted when a token holder votes on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is successfully executed.

5. **Modifiers**:
   - `nonReentrant`: Ensures no reentrancy is possible during the `vote` function.
   - `onlyOwner`: Restricts access to certain functions like fund management and proposal execution.

### Deployment Instructions

1. **Deploy the Contract**:
   - Ensure you have the required `votingToken` address (ERC1400 token contract address).
   - Specify the `votingDuration` in seconds (e.g., 1 week = 604800 seconds).

2. **Deploy Script**:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       // Define contract variables
       const VotingTokenAddress = "<ERC1400 Token Contract Address>";
       const VotingDuration = 604800; // 1 week in seconds

       // Get the contract factory and deploy
       const CorporateGovernanceVotingContract = await ethers.getContractFactory("CorporateGovernanceVotingContract");
       const corporateGovernanceVotingContract = await CorporateGovernanceVotingContract.deploy(VotingTokenAddress, VotingDuration);

       // Wait for deployment to complete
       await corporateGovernanceVotingContract.deployed();

       console.log("CorporateGovernanceVotingContract deployed to:", corporateGovernanceVotingContract.address);
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
   - Create unit tests for the `createProposal`, `vote`, `executeProposal`, and `setVotingDuration` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with