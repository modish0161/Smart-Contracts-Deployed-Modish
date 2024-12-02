// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AccreditedInvestorDAO is Ownable, ReentrancyGuard, Pausable, ERC1404 {
    using SafeMath for uint256;

    // Struct representing a proposal
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotes;
        mapping(address => uint256) votes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    IERC1404 public accreditedToken;
    uint256 public votingDuration;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => bool) public accreditedInvestors;

    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 votes
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        bool success
    );

    constructor(address _accreditedToken, uint256 _votingDuration) ERC1404("Accredited Investor Token", "AIT") {
        accreditedToken = IERC1404(_accreditedToken);
        votingDuration = _votingDuration;
    }

    modifier onlyAccredited(address account) {
        require(accreditedInvestors[account], "Account is not accredited for voting");
        _;
    }

    function addAccreditedInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
    }

    function removeAccreditedInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
    }

    function createProposal(string memory description) external onlyOwner whenNotPaused {
        uint256 proposalId = proposalCount;
        proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;

        emit ProposalCreated(proposalId, description, proposal.startTime, proposal.endTime);
    }

    function vote(uint256 proposalId, uint256 votes) external onlyAccredited(msg.sender) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(accreditedToken.balanceOf(msg.sender) >= votes, "Insufficient balance for voting");

        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = votes;
        proposal.totalVotes = proposal.totalVotes.add(votes);

        emit VoteCasted(proposalId, msg.sender, votes);
    }

    function executeProposal(uint256 proposalId) external onlyOwner nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        // Implement the execution logic based on votes here
        // For example, allocating funds, approving actions, etc.

        emit ProposalExecuted(proposalId, true);
    }

    function setVotingDuration(uint256 _votingDuration) external onlyOwner {
        votingDuration = _votingDuration;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ERC1404 standard functions
    function detectTransferRestriction(address from, address to, uint256 amount) public view override returns (uint8) {
        // Custom logic for restriction codes
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            return 1; // Not accredited
        }
        return 0; // No restriction
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Sender or receiver is not an accredited investor.";
        }
        return "No restriction.";
    }
}

