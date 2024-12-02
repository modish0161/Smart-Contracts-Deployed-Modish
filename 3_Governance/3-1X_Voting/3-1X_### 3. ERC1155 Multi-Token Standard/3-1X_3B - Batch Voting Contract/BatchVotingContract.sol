// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BatchVotingContract is Ownable, ReentrancyGuard, ERC1155Holder {
    using Counters for Counters.Counter;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 totalVotes;
        bool executed;
        uint256 deadline;
        mapping(uint256 => uint256) votesPerToken; // tokenId => vote count
    }

    // ERC1155 token used for voting
    IERC1155 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address and token ID
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Event for proposal creation
    event ProposalCreated(uint256 indexed proposalId, string title, string description, uint256 deadline);

    // Event for batch voting
    event BatchVoted(address indexed voter, uint256[] proposalIds, uint256[] tokenIds, uint256[] votePowers);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Constructor to initialize the contract with the ERC1155 token and voting duration
    constructor(IERC1155 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a proposal
    function createProposal(string calldata _title, string calldata _description) external onlyOwner {
        uint256 proposalId = proposalCounter.current();
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.title = _title;
        proposal.description = _description;
        proposal.totalVotes = 0;
        proposal.executed = false;
        proposal.deadline = block.timestamp + votingDuration;
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, proposal.deadline);
    }

    // Function to batch vote on multiple proposals with specific token types
    function batchVote(uint256[] calldata _proposalIds, uint256[] calldata _tokenIds) external nonReentrant {
        require(_proposalIds.length == _tokenIds.length, "Proposal and token arrays must have the same length");

        uint256[] memory votePowers = new uint256[](_proposalIds.length);

        for (uint256 i = 0; i < _proposalIds.length; i++) {
            Proposal storage proposal = proposals[_proposalIds[i]];

            require(block.timestamp <= proposal.deadline, "Voting period has ended for proposal");
            require(!hasVoted[_proposalIds[i]][msg.sender][_tokenIds[i]], "You have already voted with this token for proposal");

            uint256 votePower = votingToken.balanceOf(msg.sender, _tokenIds[i]);
            require(votePower > 0, "You have no voting power with this token");

            proposal.votesPerToken[_tokenIds[i]] += votePower;
            proposal.totalVotes += votePower;
            hasVoted[_proposalIds[i]][msg.sender][_tokenIds[i]] = true;
            votePowers[i] = votePower;
        }

        emit BatchVoted(msg.sender, _proposalIds, _tokenIds, votePowers);
    }

    // Function to execute a proposal based on a simple majority rule
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        // Logic to check if the proposal has reached the required threshold or majority
        if (proposal.totalVotes > 0) {
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
        bool executed,
        uint256 deadline
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.totalVotes,
            proposal.executed,
            proposal.deadline
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

    // Function to check if a user has voted with a specific token ID on a specific proposal
    function hasUserVoted(uint256 _proposalId, address _user, uint256 _tokenId) external view returns (bool) {
        return hasVoted[_proposalId][_user][_tokenId];
    }
}
