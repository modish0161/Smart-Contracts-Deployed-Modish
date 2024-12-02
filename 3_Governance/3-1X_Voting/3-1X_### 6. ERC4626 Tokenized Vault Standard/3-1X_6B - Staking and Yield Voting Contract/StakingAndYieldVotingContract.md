### Smart Contract: 3-1X_6B_StakingAndYieldVotingContract.sol

#### Overview
This smart contract enables token holders of a vault to vote on staking or yield strategies for tokenized vaults, ensuring decentralized decision-making in how the vault’s assets are managed. It adheres to the ERC4626 standard and ensures that token holders can collectively decide on strategies to maximize returns on the underlying assets.

### Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StakingAndYieldVotingContract is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 voteWeight;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        bool executed;
        uint256 deadline;
        uint256 quorumRequired;
        uint256 approvalPercentageRequired;
        bytes executionData;
    }

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Proposal ID counter
    uint256 private proposalCounter;

    // Vault token interface
    IERC4626 public vaultToken;

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
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 weight, uint256 voteType);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed account, bool status);

    // Constructor
    constructor(IERC4626 _vaultToken) {
        vaultToken = _vaultToken;
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
        bytes calldata _executionData
    ) external onlyOwner {
        require(_quorumRequired > 0 && _quorumRequired <= 100, "Invalid quorum");
        require(_approvalPercentageRequired > 0 && _approvalPercentageRequired <= 100, "Invalid approval percentage");

        uint256 proposalId = proposalCounter++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            voteWeight: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            executed: false,
            deadline: block.timestamp + 7 days, // Default voting period of 7 days
            quorumRequired: _quorumRequired,
            approvalPercentageRequired: _approvalPercentageRequired,
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

        uint256 weight = vaultToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.voteCount += 1;
        proposal.voteWeight += weight;
        hasVoted[_proposalId][msg.sender] = true;

        if (_voteType == 1) {
            proposal.yesVotes += weight;
        } else if (_voteType == 2) {
            proposal.noVotes += weight;
        } else if (_voteType == 3) {
            proposal.abstainVotes += weight;
        }

        emit VoteCast(msg.sender, _proposalId, weight, _voteType);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = vaultToken.totalAssets();
        uint256 requiredQuorum = (totalSupply * proposal.quorumRequired) / 100;
        uint256 approvalPercentage = (proposal.yesVotes * 100) / proposal.voteWeight;

        bool quorumReached = proposal.voteWeight >= requiredQuorum;
        bool approved = approvalPercentage >= proposal.approvalPercentageRequired;

        if (quorumReached && approved) {
            proposal.executed = true;
            (bool success,) = address(this).call(proposal.executionData);
            emit ProposalExecuted(_proposalId, success);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to set a custom voting period for proposals
    function setCustomVotingPeriod(uint256 _proposalId, uint256 _duration) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        proposal.deadline = block.timestamp + _duration;
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
            uint256 yesVotes,
            uint256 noVotes,
            uint256 abstainVotes,
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
            proposal.yesVotes,
            proposal.noVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.deadline,
            proposal.quorumRequired,
            proposal.approvalPercentageRequired
        );
    }

    // Function to get the total number of proposals
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }
}
```

### Contract Explanation

1. **Contract Type**:
   - The contract is built on the ERC4626 standard to enable governance and yield strategy decisions for tokenized vaults.

2. **Core Functionalities**:
   - **Whitelist Management**:
     - `addWhitelist`: Adds an address to the whitelist for voting.
     - `removeWhitelist`: Removes an address from the whitelist.
     - `isWhitelisted`: Checks if an address is whitelisted.
   - **Proposal Management**:
     - `createProposal`: Allows the owner to create a proposal with quorum, approval percentage, and execution data.
     - `vote`: Allows whitelisted addresses to vote on proposals with three options: Yes, No, and Abstain.
     - `executeProposal`: Executes the proposal if the required quorum and approval percentage are met.
   - **Proposal Information**:
     - `getProposal`: Returns the details of a specific proposal.
     - `getTotalProposals`: Returns the total number of proposals.

3. **Governance Mechanism**:
   - **Voting Options**: Voters can choose from three options: Yes, No, and Abstain.
   - **Quorum & Approval Percentage**: Proposals require a certain quorum and approval percentage to be executed.
   - **Execution Data**: Proposals can include execution data to perform specific actions upon approval.

4. **Security and Compliance**:
   - **Restricted Voting**: Only whitelisted addresses can participate in voting.
   - **ReentrancyGuard**: Prevents reentrancy attacks on state-modifying functions.

5. **Events**:
   - `ProposalCreated`: Emitted when a new proposal is created.
   - `VoteCast`: Emitted when a vote is cast on a proposal.
   - `ProposalExecuted`: Emitted when a proposal is executed, indicating

 success or failure.

6. **Additional Considerations**:
   - The contract can be further extended to include compliance checks and reporting mechanisms as needed for regulatory adherence.

### Deployment and Testing

1. **Deployment**:
   - Deploy the contract on the desired blockchain network using a framework like Hardhat or Truffle.
   - Use the provided deployment script to automate the deployment process.

2. **Testing**:
   - Write unit tests to cover the core functionalities such as creating proposals, voting, and executing proposals.
   - Test edge cases, such as exceeding voting deadlines, insufficient quorum, and invalid addresses.

3. **Additional Features**:
   - Integration with Chainlink oracles for real-time data feeds.
   - Integration with DeFi protocols for staking or yield farming based on voted strategies.