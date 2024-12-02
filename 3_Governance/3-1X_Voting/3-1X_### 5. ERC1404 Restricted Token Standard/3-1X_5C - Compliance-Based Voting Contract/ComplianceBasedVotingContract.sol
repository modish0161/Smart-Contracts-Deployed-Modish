// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ComplianceBasedVotingContract is ERC1404, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 voteWeight;
        bool executed;
        uint256 deadline;
        uint256 quorumRequired;
        uint256 approvalPercentageRequired;
    }

    // ERC1404 token used for voting
    ERC1404 public votingToken;

    // Proposal ID counter
    uint256 private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track if a user has voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Whitelisted addresses for voting
    EnumerableSet.AddressSet private whitelistedAddresses;

    // Voting duration for proposals
    uint256 public votingDuration;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorumRequired,
        uint256 approvalPercentageRequired,
        uint256 deadline
    );

    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed account, bool status);
    event ComplianceReported(address indexed regulator, uint256 proposalId, bool success);

    // Constructor
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        ERC1404 _votingToken,
        uint256 _votingDuration
    ) ERC1404(name, symbol, decimals) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
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
        uint256 _approvalPercentageRequired
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
            executed: false,
            deadline: block.timestamp + votingDuration,
            quorumRequired: _quorumRequired,
            approvalPercentageRequired: _approvalPercentageRequired
        });

        emit ProposalCreated(
            proposalId,
            _title,
            _description,
            _quorumRequired,
            _approvalPercentageRequired,
            block.timestamp + votingDuration
        );
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId) external onlyWhitelisted nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 weight = votingToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.voteCount += 1;
        proposal.voteWeight += weight;
        hasVoted[_proposalId][msg.sender] = true;

        emit VoteCast(msg.sender, _proposalId, weight);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredQuorum = (totalSupply * proposal.quorumRequired) / 100;
        uint256 approvalPercentage = (proposal.voteWeight * 100) / totalSupply;

        bool quorumReached = proposal.voteWeight >= requiredQuorum;
        bool approved = approvalPercentage >= proposal.approvalPercentageRequired;

        if (quorumReached && approved) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
            reportCompliance(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
            reportCompliance(_proposalId, false);
        }
    }

    // Function to report compliance to a regulatory body
    function reportCompliance(uint256 _proposalId, bool _success) internal {
        address regulator = owner(); // Assume owner is the regulator for reporting purposes
        emit ComplianceReported(regulator, _proposalId, _success);
    }

    // Function to set voting duration
    function setVotingDuration(uint256 _duration) external onlyOwner {
        votingDuration = _duration;
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
