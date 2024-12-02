// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VaultGovernanceDAO is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Governance proposal structure
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 totalVotes;
        uint256 requiredApproval; // Required percentage of votes for proposal approval
        mapping(address => uint256) votes;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved;
    }

    IERC20 public governanceToken; // Governance token for voting
    uint256 public votingDuration; // Duration of the voting period
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => bool) public vaultParticipants; // Vault participants allowed to vote

    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        uint256 startTime,
        uint256 endTime,
        uint256 requiredApproval
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

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _governanceToken,
        uint256 _votingDuration
    ) ERC4626(IERC20(_asset)) ERC20(_name, _symbol) {
        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
    }

    modifier onlyVaultParticipant(address account) {
        require(vaultParticipants[account], "Not a vault participant");
        _;
    }

    function addVaultParticipant(address participant) external onlyOwner {
        vaultParticipants[participant] = true;
    }

    function removeVaultParticipant(address participant) external onlyOwner {
        vaultParticipants[participant] = false;
    }

    function createProposal(string memory description, uint256 requiredApproval) external onlyOwner whenNotPaused {
        require(requiredApproval <= 100, "Approval percentage must be <= 100");

        uint256 proposalId = proposalCount;
        proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;
        proposal.requiredApproval = requiredApproval;

        emit ProposalCreated(proposalId, description, proposal.startTime, proposal.endTime, requiredApproval);
    }

    function vote(uint256 proposalId, uint256 votes) external onlyVaultParticipant(msg.sender) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(governanceToken.balanceOf(msg.sender) >= votes, "Insufficient governance token balance");

        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = votes;
        proposal.totalVotes = proposal.totalVotes.add(votes);

        emit VoteCasted(proposalId, msg.sender, votes);
    }

    function executeProposal(uint256 proposalId) external onlyOwner nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 approvalPercentage = proposal.totalVotes.mul(100).div(totalSupply());
        proposal.approved = approvalPercentage >= proposal.requiredApproval;
        proposal.executed = true;

        emit ProposalExecuted(proposalId, proposal.approved);
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
}
