// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DividendsAndDistributionVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Struct for Dividend Proposal
    struct DividendProposal {
        uint256 id;
        string title;
        string description;
        uint256 totalVotes;
        uint256 totalTokensVoted;
        bool executed;
        uint256 deadline;
        uint256 requiredQuorum;
        uint256 approvalPercentage;
        uint256 distributionAmount; // Amount to be distributed as dividends
    }

    // ERC1400 security token used for voting
    IERC1400 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store dividend proposals
    mapping(uint256 => DividendProposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Event for proposal creation
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 requiredQuorum,
        uint256 approvalPercentage,
        uint256 distributionAmount,
        uint256 deadline
    );

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Constructor to initialize the contract with the ERC1400 token, voting duration, and default quorum
    constructor(IERC1400 _votingToken, uint256 _votingDuration) {
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a dividend proposal with a specified quorum, approval percentage, and distribution amount
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _requiredQuorum,
        uint256 _approvalPercentage,
        uint256 _distributionAmount
    ) external onlyOwner {
        require(_requiredQuorum > 0 && _requiredQuorum <= 100, "Quorum must be between 1 and 100");
        require(_approvalPercentage > 0 && _approvalPercentage <= 100, "Approval percentage must be between 1 and 100");
        require(_distributionAmount > 0, "Distribution amount must be greater than zero");

        uint256 proposalId = proposalCounter.current();
        DividendProposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.title = _title;
        proposal.description = _description;
        proposal.totalVotes = 0;
        proposal.totalTokensVoted = 0;
        proposal.executed = false;
        proposal.deadline = block.timestamp + votingDuration;
        proposal.requiredQuorum = _requiredQuorum;
        proposal.approvalPercentage = _approvalPercentage;
        proposal.distributionAmount = _distributionAmount;
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, _requiredQuorum, _approvalPercentage, _distributionAmount, proposal.deadline);
    }

    // Function to vote on a dividend proposal
    function vote(uint256 _proposalId) external nonReentrant {
        DividendProposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.totalVotes += 1;
        proposal.totalTokensVoted += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a dividend proposal based on quorum and approval percentage rules
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        DividendProposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        uint256 totalSupply = votingToken.totalSupply();
        uint256 requiredTokens = (totalSupply * proposal.requiredQuorum) / 100;

        // Check if the proposal has reached the required quorum
        bool quorumReached = proposal.totalTokensVoted >= requiredTokens;

        // Calculate approval percentage
        uint256 approval = (proposal.totalTokensVoted * 100) / totalSupply;

        // Execute the proposal if quorum is reached and approval percentage is met
        if (quorumReached && approval >= proposal.approvalPercentage) {
            proposal.executed = true;
            distributeDividends(proposal.distributionAmount);
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to distribute dividends based on the proposal approval
    function distributeDividends(uint256 _amount) internal {
        uint256 totalSupply = votingToken.totalSupply();
        for (uint256 i = 0; i < totalSupply; i++) {
            address shareholder = votingToken.holderAt(i);
            uint256 shareholderBalance = votingToken.balanceOf(shareholder);
            uint256 dividendShare = (_amount * shareholderBalance) / totalSupply;
            payable(shareholder).transfer(dividendShare);
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
        uint256 requiredQuorum,
        uint256 approvalPercentage,
        uint256 distributionAmount
    ) {
        DividendProposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.totalVotes,
            proposal.totalTokensVoted,
            proposal.executed,
            proposal.deadline,
            proposal.requiredQuorum,
            proposal.approvalPercentage,
            proposal.distributionAmount
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

    // Function to deposit funds to the contract for dividend distribution
    function deposit() external payable onlyOwner {}

    // Function to withdraw funds from the contract
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        payable(owner()).transfer(_amount);
    }
}
