### Smart Contract: 3-1X_5B_AccreditedInvestorVotingContract.sol

#### Overview
This smart contract allows only accredited investors (or qualified participants) to vote on key governance decisions. It uses the ERC1404 standard to restrict participation to compliant or whitelisted investors, ensuring regulatory compliance.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract AccreditedInvestorVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 voteWeight;
        bool executed;
        uint256 deadline;
        uint256 quorumRequired;
        uint256 approvalPercentageRequired;
    }

    // ERC1404 token used for voting
    IERC1404 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track if a user has voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Whitelisted addresses for voting
    EnumerableSet.AddressSet private whitelistedAddresses;

    // Voting duration for proposals
    uint256 public votingDuration;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorumRequired,
        uint256 approvalPercentageRequired,
        uint256 deadline
    );

    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed account, bool status);

    // Constructor
    constructor(IERC1404 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
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
        uint256 _approvalPercentageRequired
    ) external onlyOwner {
        require(_quorumRequired > 0 && _quorumRequired <= 100, "Invalid quorum");
        require(_approvalPercentageRequired > 0 && _approvalPercentageRequired <= 100, "Invalid approval percentage");

        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            voteWeight: 0,
            executed: false,
            deadline: block.timestamp + votingDuration,
            quorumRequired: _quorumRequired,
            approvalPercentageRequired: _approvalPercentageRequired
        });
        
        proposalCounter.increment();

        emit ProposalCreated(
            proposalId,
            _title,
            _description,
            _quorumRequired,
            _approvalPercentageRequired,
            block.timestamp + votingDuration
        );
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId) external onlyWhitelisted nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 weight = votingToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.voteCount += 1;
        proposal.voteWeight += weight;
        hasVoted[_proposalId][msg.sender] = true;

        emit VoteCast(msg.sender, _proposalId, weight);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredQuorum = (totalSupply * proposal.quorumRequired) / 100;
        uint256 approvalPercentage = (proposal.voteWeight * 100) / totalSupply;

        bool quorumReached = proposal.voteWeight >= requiredQuorum;
        bool approved = approvalPercentage >= proposal.approvalPercentageRequired;

        if (quorumReached && approved) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to set voting duration
    function setVotingDuration(uint256 _duration) external onlyOwner {
        votingDuration = _duration;
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
            uint256 voteWeight,
            bool executed,
            uint256 deadline,
            uint256 quorumRequired,
            uint256 approvalPercentageRequired
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.voteWeight,
            proposal.executed,
            proposal.deadline,
            proposal.quorumRequired,
            proposal.approvalPercentageRequired
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
   - The contract follows the ERC1404 standard, ensuring that only accredited or whitelisted investors can vote.
   - `AccreditedInvestorVotingContract` inherits from `Ownable` and `ReentrancyGuard` to manage ownership and security.

2. **Core Functionalities**:
   - **Whitelist Management**:
     - `addWhitelist`: Adds an address to the whitelist.
     - `removeWhitelist`: Removes an address from the whitelist.
     - `isWhitelisted`: Checks if an address is whitelisted.
   - **Proposal Management**:
     - `createProposal`: Allows the owner to create a proposal with a specified quorum and approval percentage.
     - `vote`: Allows whitelisted addresses to vote on proposals based on their token balance.
     - `executeProposal`: Executes the proposal if the required quorum and approval percentage are met after the voting period ends.
   - **Proposal Information**:
     - `getProposal`: Returns the details of a specific proposal.
     - `getTotalProposals`: Returns the total number of proposals.

3. **Security and Compliance**:
   - **Whitelisted Voting**: Only addresses added to the whitelist can vote.
   - **Restricted Voting**: Ensures only accredited investors can participate in voting, adhering to ERC1404 standards.
   - **ReentrancyGuard**: Prevents reentrancy attacks on state-modifying functions.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `VoteCast`: Emitted when a vote is cast on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is executed, indicating whether it was successful or not.
   - `WhitelistUpdated`: Emitted when an address is added to or removed from the whitelist.

5. **Modifiers**:
   - `onlyWhitelisted`: Restricts access to certain functions to only whitelisted addresses.

### Deployment Instructions

1. **Deploy the Contract**:
   - Ensure you have the required `votingToken` address (ERC1404 token contract address).
   - Specify the `votingDuration` in seconds (e.g., 1 week = 604800 seconds).

2. **Deployment Script**:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       // Define contract variables
       const VotingTokenAddress = "<ERC1404 Token Contract Address>";
       const VotingDuration = 604800; // 1 week in seconds

       // Get the contract factory and deploy
       const AccreditedInvestorVotingContract = await ethers.getContractFactory("AccreditedInvestorVotingContract");
       const accreditedInvestorVotingContract = await AccreditedInvestorVotingContract.deploy(VotingTokenAddress, VotingDuration);

       // Wait for deployment to complete
       await accreditedInvestorVotingContract.deployed();

       console.log("AccreditedInvestorVotingContract deployed to:", accredited

InvestorVotingContract.address);
   }

   // Execute the script
   main()
       .then(() => process.exit(0))
       .catch((error) => {
           console.error(error);
           process.exit(1);
       });
   ```

3. **Testing & Verification**:
   - Create unit tests for the `createProposal`, `vote`, `executeProposal`, `addWhitelist`, and `removeWhitelist` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with the contract (creating proposals, voting, etc.).

5. **Additional Customizations**:
   - Add additional compliance checks based on KYC/AML requirements.
   - Implement more complex approval logic (e.g., different approval thresholds based on the proposal type).
   - Add features like automatic proposal creation based on external triggers or conditions.

This smart contract provides a secure and compliant mechanism for accredited investors to participate in governance decisions while restricting unauthorized access.