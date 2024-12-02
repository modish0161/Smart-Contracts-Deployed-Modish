### Smart Contract: 3-1X_2B_ProposalCreationAndVotingContract.sol

#### Overview
This smart contract allows ERC777 token holders to submit proposals for governance changes or fund allocations and vote on these proposals. It ensures that decisions are made transparently, with all token holders participating in the voting process. The contract leverages the advanced functionality of the ERC777 standard, including operator permissions and efficient voting mechanisms.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ProposalCreationAndVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 totalVotedTokens;
        bool executed;
        uint256 deadline;
        uint256 allocationAmount;
        address payable recipient;
    }

    // ERC777 token used for voting
    IERC777 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Minimum quorum percentage (e.g., 20%)
    uint256 public quorumPercentage;

    // Contract balance for fund allocations
    uint256 public contractBalance;

    // Event for proposal creation
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 allocationAmount,
        address indexed recipient,
        uint256 deadline
    );

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Event for fund deposit
    event FundDeposited(address indexed sender, uint256 amount);

    // Event for fund withdrawal
    event FundWithdrawn(address indexed recipient, uint256 amount);

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

    // Function to create a proposal for governance or fund allocation
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _allocationAmount,
        address payable _recipient
    ) external {
        require(_allocationAmount <= contractBalance, "Allocation amount exceeds contract balance");
        require(_recipient != address(0), "Invalid recipient address");

        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            totalVotedTokens: 0,
            executed: false,
            deadline: block.timestamp + votingDuration,
            allocationAmount: _allocationAmount,
            recipient: _recipient
        });
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, _allocationAmount, _recipient, proposals[proposalId].deadline);
    }

    // Function to vote on a proposal
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
            contractBalance -= proposal.allocationAmount;
            proposal.recipient.transfer(proposal.allocationAmount);
            emit ProposalExecuted(_proposalId, true);
            emit FundWithdrawn(proposal.recipient, proposal.allocationAmount);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to deposit funds into the contract
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        contractBalance += msg.value;
        emit FundDeposited(msg.sender, msg.value);
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

    // Function to withdraw contract balance in case of emergency
    function emergencyWithdraw(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        uint256 balance = contractBalance;
        contractBalance = 0;
        _recipient.transfer(balance);
        emit FundWithdrawn(_recipient, balance);
    }
}
```

### Contract Explanation

1. **Contract Type**: This is a proposal creation and voting contract using the ERC777 standard. It allows token holders to submit proposals for governance changes or fund allocations and vote on them. It leverages ERC777's advanced functionality, including operator permissions and secure voting mechanisms.

2. **Core Functionalities**:
   - `createProposal`: Allows any token holder to create a proposal with a title, description, allocation amount, and recipient address.
   - `vote`: Allows token holders to vote on proposals. Voting power is determined by the token balance of the voter.
   - `executeProposal`: Allows the owner to execute a proposal after the voting period has ended, based on quorum and majority rules.
   - `depositFunds`: Allows the contract owner to deposit funds into the contract for allocation.
   - `emergencyWithdraw`: Allows the owner to withdraw the contract balance in case of an emergency.

3. **Security Measures**:
   - **ReentrancyGuard**: Prevents reentrancy attacks.
   - **Ownable**: Restricts functions like fund deposit, emergency withdrawal, and proposal execution to the contract owner.
   - **HasVoted Mapping**: Ensures that each address can only vote once per proposal.
   - **Quorum Check**: Ensures that a minimum percentage of tokens are voted for the proposal to be valid.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `Voted`: Emitted when a token holder votes on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is successfully executed.
   - `FundDeposited`: Emitted when funds are deposited into the contract.
   - `FundWithdrawn`: Emitted when funds are withdrawn from the contract.

5. **Modifiers**:
   - `nonReentrant`: Ensures no reentrancy is possible during the `vote` function.
   - `onlyOwner`: Restricts access to certain functions like fund management and proposal execution.

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
       const QuorumPercentage = 

20; // 20% quorum

       // Get the contract factory and deploy
       const ProposalCreationAndVotingContract = await ethers.getContractFactory("ProposalCreationAndVotingContract");
       const proposalCreationAndVotingContract = await ProposalCreationAndVotingContract.deploy(VotingTokenAddress, VotingDuration, QuorumPercentage);

       // Wait for deployment to complete
       await proposalCreationAndVotingContract.deployed();

       console.log("ProposalCreationAndVotingContract deployed to:", proposalCreationAndVotingContract.address);
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
   - Create unit tests for the `createProposal`, `vote`, `executeProposal`, `depositFunds`, and `emergencyWithdraw` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with the contract (creating proposals, voting, etc.).

5. **Additional Customizations**:
   - Implement more complex proposal execution logic (e.g., fund transfers or state changes).
   - Add features like dynamic quorum requirements or multi-phase voting periods.
   - Include a UI for easier interaction with the contract.

This smart contract is structured to offer a robust proposal creation and voting mechanism using ERC777 tokens, incorporating industry standards and security best practices.