### Smart Contract: 3-1X_5A_RestrictedVotingContract.sol

#### Overview
This smart contract enables only authorized token holders (such as accredited investors or whitelisted addresses) to participate in governance decisions. The contract leverages the ERC1404 restricted token standard to ensure that only compliant or whitelisted participants can vote on key governance issues.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract RestrictedVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Struct for Governance Proposal
    struct GovernanceProposal {
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

    // ERC1404 restricted token used for voting
    IERC1404 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store governance proposals
    mapping(uint256 => GovernanceProposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Mapping to whitelist addresses for voting
    EnumerableSet.AddressSet private whitelistedAddresses;

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

    // Event for adding/removing from whitelist
    event Whitelisted(address indexed account, bool isWhitelisted);

    // Constructor to initialize the contract with the ERC1404 token, voting duration, and default quorum
    constructor(IERC1404 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Modifier to check if an address is whitelisted
    modifier onlyWhitelisted() {
        require(whitelistedAddresses.contains(msg.sender), "You are not whitelisted");
        _;
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        require(!whitelistedAddresses.contains(_account), "Address already whitelisted");
        whitelistedAddresses.add(_account);
        emit Whitelisted(_account, true);
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address _account) external onlyOwner {
        require(whitelistedAddresses.contains(_account), "Address not in whitelist");
        whitelistedAddresses.remove(_account);
        emit Whitelisted(_account, false);
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistedAddresses.contains(_account);
    }

    // Function to create a governance proposal with a specified quorum and approval percentage
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requiredQuorum,
        uint256 _approvalPercentage
    ) external onlyOwner {
        require(_requiredQuorum > 0 && _requiredQuorum <= 100, "Quorum must be between 1 and 100");
        require(_approvalPercentage > 0 && _approvalPercentage <= 100, "Approval percentage must be between 1 and 100");

        uint256 proposalId = proposalCounter.current();
        GovernanceProposal storage proposal = proposals[proposalId];
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

    // Function to vote on a governance proposal
    function vote(uint256 _proposalId) external onlyWhitelisted nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.totalVotes += 1;
        proposal.totalTokensVoted += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a governance proposal based on quorum and approval percentage rules
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];

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
        GovernanceProposal storage proposal = proposals[_proposalId];
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

1. **Contract Type**: The contract uses the ERC1404 restricted token standard to ensure that only whitelisted, compliant, or authorized token holders can vote on governance decisions.

2. **Core Functionalities**:
   - `addToWhitelist` and `removeFromWhitelist`: These functions allow the contract owner to manage the whitelist of addresses that can vote on proposals.
   - `createProposal`: Allows the contract owner to create a new proposal with a title, description, quorum requirement, and approval percentage.
   - `vote`: Allows whitelisted token holders to vote on proposals. Voting power is determined by the token balance of the voter.
   - `executeProposal`: Allows the owner to execute a proposal after the voting period has ended, based on quorum and approval percentage rules.

3. **Security Measures**:
   - **ReentrancyGuard**: Prevents reentrancy attacks.
   - **Ownable**: Restricts proposal creation, fund management, and proposal execution to the contract owner.
   - **HasVoted Mapping**: Ensures that each address can only vote once per proposal.
   - **Quorum and Approval Check**: Ensures that a proposal can only be executed if it reaches the required quorum and approval percentage.
   - **Whitelisted Voting**: Only whitelisted addresses can vote on proposals.

4. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `Voted`: Emitted when a token holder votes on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is successfully executed.
   - `Whitelisted`: Emitted when an address is added to or removed from the whitelist.

5. **Modifiers**:
   - `onlyWhitelisted`: Ensures that only whitelisted addresses can call the function.

### Deployment Instructions

1. **Deploy the Contract**:
   - Ensure you have the required `votingToken` address (ERC1404 token contract address).
   - Specify the `

votingDuration` in seconds (e.g., 1 week = 604800 seconds).

2. **Deployment Script**:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       // Define contract variables
       const VotingTokenAddress = "<ERC1404 Token Contract Address>";
       const VotingDuration = 604800; // 1 week in seconds

       // Get the contract factory and deploy
       const RestrictedVotingContract = await ethers.getContractFactory("RestrictedVotingContract");
       const restrictedVotingContract = await RestrictedVotingContract.deploy(VotingTokenAddress, VotingDuration);

       // Wait for deployment to complete
       await restrictedVotingContract.deployed();

       console.log("RestrictedVotingContract deployed to:", restrictedVotingContract.address);
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
   - Create unit tests for the `createProposal`, `vote`, `executeProposal`, `addToWhitelist`, and `removeFromWhitelist` functions.
   - Use a local Ethereum test network (e.g., Hardhat) for initial testing.
   - Verify the contract on Etherscan using the contract source code.

4. **Documentation**:
   - Provide an API documentation detailing function inputs, outputs, and events.
   - Include user guides for interacting with the contract (creating proposals, voting, etc.).

5. **Additional Customizations**:
   - Add additional compliance checks based on KYC/AML requirements.
   - Implement more complex approval logic (e.g., different approval thresholds based on the proposal type).
   - Add features like automatic proposal creation based on external triggers or conditions.