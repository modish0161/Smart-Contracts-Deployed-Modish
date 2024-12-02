// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998ERC721TopDown.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiLayerDAOGovernance is ERC998ERC721TopDown, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Struct for governance proposals
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool approved;
    }

    Counters.Counter private proposalCounter;
    IERC721 public governanceToken;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    uint256 public votingDuration; // Duration of voting in seconds
    uint256 public minimumTokenThreshold; // Minimum number of governance tokens required to create a proposal

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);

    constructor(
        string memory _name,
        string memory _symbol,
        address _governanceToken,
        uint256 _votingDuration,
        uint256 _minimumTokenThreshold
    ) ERC998ERC721TopDown(_name, _symbol) {
        governanceToken = IERC721(_governanceToken);
        votingDuration = _votingDuration;
        minimumTokenThreshold = _minimumTokenThreshold;
    }

    modifier hasMinimumTokens(address account) {
        require(governanceToken.balanceOf(account) >= minimumTokenThreshold, "Not enough governance tokens");
        _;
    }

    // Function to create a new proposal
    function createProposal(string memory description) external hasMinimumTokens(msg.sender) whenNotPaused {
        uint256 proposalId = proposalCounter.current();
        proposalCounter.increment();

        proposals[proposalId] = Proposal({
            description: description,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            approved: false
        });

        emit ProposalCreated(proposalId, description, block.timestamp, block.timestamp + votingDuration);
    }

    // Function to vote on a proposal
    function vote(uint256 proposalId, bool support) external hasMinimumTokens(msg.sender) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        if (support) {
            proposal.forVotes = proposal.forVotes.add(weight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(weight);
        }

        hasVoted[proposalId][msg.sender] = true;
        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    // Function to execute a proposal
    function executeProposal(uint256 proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.forVotes > proposal.againstVotes) {
            proposal.approved = true;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.approved);
    }

    // Function to set the minimum token threshold for creating proposals
    function setMinimumTokenThreshold(uint256 _minimumTokenThreshold) external onlyOwner {
        minimumTokenThreshold = _minimumTokenThreshold;
    }

    // Function to set the voting duration for proposals
    function setVotingDuration(uint256 _votingDuration) external onlyOwner {
        votingDuration = _votingDuration;
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
