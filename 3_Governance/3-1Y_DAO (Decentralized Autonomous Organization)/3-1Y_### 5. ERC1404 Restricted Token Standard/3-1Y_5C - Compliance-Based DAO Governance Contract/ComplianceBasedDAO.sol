// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ComplianceBasedDAO is Ownable, ReentrancyGuard, Pausable, ERC1404 {
    using SafeMath for uint256;

    // Struct representing a proposal
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

    IERC1404 public complianceToken;
    uint256 public votingDuration;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(address => bool) public compliantStakeholders;

    // Chainlink price feed for reporting to regulatory bodies
    AggregatorV3Interface internal priceFeed;

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

    event ComplianceReport(
        uint256 indexed proposalId,
        uint256 totalVotes,
        bool approved,
        uint256 timestamp,
        string priceFeedReport
    );

    constructor(address _complianceToken, uint256 _votingDuration, address _priceFeed) ERC1404("Compliance Token", "CTK") {
        complianceToken = IERC1404(_complianceToken);
        votingDuration = _votingDuration;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyCompliant(address account) {
        require(compliantStakeholders[account], "Account is not compliant for voting");
        _;
    }

    function addCompliantStakeholder(address stakeholder) external onlyOwner {
        compliantStakeholders[stakeholder] = true;
    }

    function removeCompliantStakeholder(address stakeholder) external onlyOwner {
        compliantStakeholders[stakeholder] = false;
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

    function vote(uint256 proposalId, uint256 votes) external onlyCompliant(msg.sender) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(complianceToken.balanceOf(msg.sender) >= votes, "Insufficient balance for voting");

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

        // Report to regulatory bodies
        _reportToRegulatoryBodies(proposalId);
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

    // Report proposal outcomes and compliance to regulatory bodies
    function _reportToRegulatoryBodies(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        (,int price,,,) = priceFeed.latestRoundData();

        emit ComplianceReport(
            proposalId,
            proposal.totalVotes,
            proposal.approved,
            block.timestamp,
            string(abi.encodePacked("Latest price from price feed: ", uint256(price).toString()))
        );
    }

    // ERC1404 standard functions
    function detectTransferRestriction(address from, address to, uint256 amount) public view override returns (uint8) {
        // Custom logic for restriction codes
        if (!compliantStakeholders[from] || !compliantStakeholders[to]) {
            return 1; // Not compliant
        }
        return 0; // No restriction
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Sender or receiver is not a compliant stakeholder.";
        }
        return "No restriction.";
    }
}
