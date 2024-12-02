// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiLayeredVotingContract is Ownable, ReentrancyGuard, Pausable {
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
        address[] affectedAssets;
        bytes[] executionData;
    }

    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public whitelist;

    uint256 public constant VOTING_PERIOD = 7 days;

    ERC721Enumerable public erc998Token;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorum,
        uint256 approvalPercentage,
        uint256 endTime
    );

    event VoteCasted(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "You are not authorized to vote");
        _;
    }

    constructor(address _erc998Token) {
        erc998Token = ERC721Enumerable(_erc998Token);
    }

    function addWhitelist(address voter) external onlyOwner {
        whitelist[voter] = true;
    }

    function removeWhitelist(address voter) external onlyOwner {
        whitelist[voter] = false;
    }

    function createProposal(
        string memory title,
        string memory description,
        uint256 quorum,
        uint256 approvalPercentage,
        address[] memory affectedAssets,
        bytes[] memory executionData
    ) external onlyOwner whenNotPaused {
        require(quorum > 0 && quorum <= 100, "Invalid quorum percentage");
        require(
            approvalPercentage > 0 && approvalPercentage <= 100,
            "Invalid approval percentage"
        );
        require(
            affectedAssets.length == executionData.length,
            "Mismatched assets and data"
        );

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
            endTime: block.timestamp + VOTING_PERIOD,
            affectedAssets: affectedAssets,
            executionData: executionData
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

    function vote(uint256 proposalId, bool support)
        external
        onlyWhitelisted
        whenNotPaused
        nonReentrant
    {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp < proposal.endTime,
            "Voting period has ended"
        );
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 weight = erc998Token.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(weight);
        } else {
            proposal.noVotes = proposal.noVotes.add(weight);
        }

        hasVoted[proposalId][msg.sender] = true;

        emit VoteCasted(msg.sender, proposalId, support, weight);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 quorumVotes = erc998Token.totalSupply().mul(proposal.quorum).div(100);
        uint256 approvalVotes = proposal.yesVotes.mul(100).div(totalVotes);

        require(totalVotes >= quorumVotes, "Quorum not reached");
        require(approvalVotes >= proposal.approvalPercentage, "Approval percentage not reached");

        for (uint256 i = 0; i < proposal.affectedAssets.length; i++) {
            (bool success, ) = proposal.affectedAssets[i].call(
                proposal.executionData[i]
            );
            require(success, "Execution failed for asset");
        }

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
