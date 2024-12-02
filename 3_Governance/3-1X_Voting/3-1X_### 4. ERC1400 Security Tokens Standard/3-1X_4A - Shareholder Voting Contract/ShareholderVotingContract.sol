// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ShareholderVotingContract is Ownable, ReentrancyGuard {
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
    event ProposalCreated(uint256 indexed proposalId, string title, string description, uint256 requiredQuorum, uint256 deadline);

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Constructor to initialize the contract with the ERC1400 token, voting duration, and default quorum
    constructor(IERC1400 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a proposal with a specified quorum
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requiredQuorum
    ) external onlyOwner {
        require(_requiredQuorum > 0, "Quorum must be greater than zero");

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
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, _requiredQuorum, proposal.deadline);
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

    // Function to execute a proposal based on quorum and majority rules
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredTokens = (totalSupply * proposal.requiredQuorum) / 100;

        // Check if the proposal has reached the required quorum
        bool quorumReached = proposal.totalTokensVoted >= requiredTokens;

        // Execute the proposal if quorum is reached
        if (quorumReached) {
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
        uint256 requiredQuorum
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
            proposal.requiredQuorum
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
