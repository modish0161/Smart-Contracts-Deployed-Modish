// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IAnonCreds {
    function isValidProof(bytes memory proof) external view returns (bool);
    function verifyProof(
        bytes memory proof,
        bytes32 root,
        bytes32[] memory nullifiers,
        bytes32 signal
    ) external view returns (bool);
}

contract PrivacyPreservingDAOGovernance is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    IERC20 public governanceToken;
    IAnonCreds public anonCreds;

    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool approved;
    }

    uint256 public proposalCount;
    uint256 public votingDuration;
    uint256 public minimumTokenThreshold;
    bytes32 public merkleRoot;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 startTime, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, bytes32 indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool approved);

    constructor(
        address _governanceToken,
        address _anonCreds,
        uint256 _votingDuration,
        uint256 _minimumTokenThreshold,
        bytes32 _merkleRoot
    ) {
        governanceToken = IERC20(_governanceToken);
        anonCreds = IAnonCreds(_anonCreds);
        votingDuration = _votingDuration;
        minimumTokenThreshold = _minimumTokenThreshold;
        merkleRoot = _merkleRoot;
    }

    modifier hasMinimumTokens(address account) {
        require(governanceToken.balanceOf(account) >= minimumTokenThreshold, "Not enough governance tokens");
        _;
    }

    function createProposal(string memory description) external hasMinimumTokens(msg.sender) whenNotPaused {
        proposalCount = proposalCount.add(1);
        uint256 proposalId = proposalCount;

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

    function vote(
        uint256 proposalId,
        bool support,
        bytes memory proof,
        bytes32[] memory nullifiers,
        bytes32 signal
    ) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting has ended");
        require(anonCreds.verifyProof(proof, merkleRoot, nullifiers, signal), "Invalid proof or not eligible");
        require(!hasVoted[proposalId][signal], "Already voted");

        if (support) {
            proposal.forVotes = proposal.forVotes.add(1);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(1);
        }

        hasVoted[proposalId][signal] = true;
        emit VoteCast(proposalId, signal, support);
    }

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

    function setMinimumTokenThreshold(uint256 _minimumTokenThreshold) external onlyOwner {
        minimumTokenThreshold = _minimumTokenThreshold;
    }

    function setVotingDuration(uint256 _votingDuration) external onlyOwner {
        votingDuration = _votingDuration;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
