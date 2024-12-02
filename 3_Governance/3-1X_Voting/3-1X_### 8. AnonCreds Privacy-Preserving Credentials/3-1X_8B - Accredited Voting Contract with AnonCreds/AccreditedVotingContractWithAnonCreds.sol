// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for AnonCreds-based identity verification and privacy-preserving voting
interface IAnonCreds {
    function verifyProof(bytes memory proof, bytes32[] memory merkleProof, bytes32 root) external view returns (bool);
    function getRootHash() external view returns (bytes32);
}

contract AccreditedVotingContractWithAnonCreds is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Proposal {
        string title;
        string description;
        uint256 quorum;
        uint256 approvalPercentage;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        uint256 endTime;
    }

    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(bytes32 => bool)) public hasVoted;

    uint256 public constant VOTING_PERIOD = 7 days;
    bytes32 public rootHash;

    IAnonCreds public anonCredsVerifier;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorum,
        uint256 approvalPercentage,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _anonCredsVerifier) {
        anonCredsVerifier = IAnonCreds(_anonCredsVerifier);
    }

    function setRootHash(bytes32 _rootHash) external onlyOwner {
        rootHash = _rootHash;
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 quorum,
        uint256 approvalPercentage
    ) external onlyOwner whenNotPaused {
        require(quorum > 0 && quorum <= 100, "Invalid quorum percentage");
        require(approvalPercentage > 0 && approvalPercentage <= 100, "Invalid approval percentage");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            title: title,
            description: description,
            quorum: quorum,
            approvalPercentage: approvalPercentage,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            endTime: block.timestamp + VOTING_PERIOD
        });

        emit ProposalCreated(
            proposalId,
            title,
            description,
            quorum,
            approvalPercentage,
            block.timestamp + VOTING_PERIOD
        );
    }

    function vote(uint256 proposalId, bool support, bytes memory proof, bytes32[] memory merkleProof)
        external
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended");

        bytes32 leaf = keccak256(proof);
        require(!hasVoted[proposalId][leaf], "Already voted");

        // Verify the zero-knowledge proof
        require(anonCredsVerifier.verifyProof(proof, merkleProof, rootHash), "Invalid proof");

        // Assume the weight of the vote is 1, as privacy-preserving proofs do not reveal vote weight
        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(1);
        } else {
            proposal.noVotes = proposal.noVotes.add(1);
        }

        hasVoted[proposalId][leaf] = true;

        emit VoteCasted(proposalId, support, 1);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 quorumVotes = totalVotes.mul(proposal.quorum).div(100);
        uint256 approvalVotes = proposal.yesVotes.mul(100).div(totalVotes);

        require(totalVotes >= quorumVotes, "Quorum not reached");
        require(approvalVotes >= proposal.approvalPercentage, "Approval percentage not reached");

        proposal.executed = true;

        emit ProposalExecuted(proposalId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
