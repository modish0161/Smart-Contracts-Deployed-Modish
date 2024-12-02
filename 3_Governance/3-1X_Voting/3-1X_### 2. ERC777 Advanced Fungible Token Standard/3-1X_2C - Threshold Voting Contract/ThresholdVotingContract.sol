// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ThresholdVotingContract is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Struct for Proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 totalVotedTokens;
        bool executed;
        uint256 deadline;
        uint256 threshold;
    }

    // ERC777 token used for voting
    IERC777 public votingToken;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Mapping to track voting status of a proposal by an address
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Voting duration in seconds (e.g., 1 week)
    uint256 public votingDuration;

    // Contract balance for fund allocations (if needed)
    uint256 public contractBalance;

    // Event for proposal creation
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 threshold,
        uint256 deadline
    );

    // Event for voting
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 votePower);

    // Event for proposal execution
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // Event for fund deposit
    event FundDeposited(address indexed sender, uint256 amount);

    // Constructor to initialize the contract with the ERC777 token, voting duration, and default threshold
    constructor(
        IERC777 _votingToken,
        uint256 _votingDuration,
        uint256 _defaultThreshold
    ) {
        require(_defaultThreshold > 0, "Threshold must be greater than zero");
        votingToken = _votingToken;
        votingDuration = _votingDuration;
    }

    // Function to create a proposal with a custom threshold
    function createProposal(
        string calldata _title,
        string calldata _description,
        uint256 _threshold
    ) external onlyOwner {
        require(_threshold > 0, "Threshold must be greater than zero");

        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            totalVotedTokens: 0,
            executed: false,
            deadline: block.timestamp + votingDuration,
            threshold: _threshold
        });
        proposalCounter.increment();

        emit ProposalCreated(proposalId, _title, _description, _threshold, proposals[proposalId].deadline);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal");

        uint256 votePower = votingToken.balanceOf(msg.sender);
        require(votePower > 0, "You have no voting power");

        proposal.voteCount += 1;
        proposal.totalVotedTokens += votePower;
        hasVoted[_proposalId][msg.sender] = true;

        emit Voted(msg.sender, _proposalId, votePower);
    }

    // Function to execute a proposal based on the threshold rule
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");

        // Check if the proposal has reached the required threshold
        bool thresholdReached = proposal.totalVotedTokens >= proposal.threshold;

        // Execute the proposal if the threshold is reached
        if (thresholdReached) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
            // Additional logic for proposal execution goes here (e.g., governance changes)
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }

    // Function to deposit funds into the contract (if needed for proposals)
    function depositFunds() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        contractBalance += msg.value;
        emit FundDeposited(msg.sender, msg.value);
    }

    // Function to get proposal details
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // Function to get total number of proposals
    function getProposalCount() external view returns (uint256) {
        return proposalCounter.current();
    }

    // Function to set a new voting duration
    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    // Function to withdraw contract balance in case of emergency
    function emergencyWithdraw(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        uint256 balance = contractBalance;
        contractBalance = 0;
        _recipient.transfer(balance);
        emit FundDeposited(_recipient, balance);
    }
}
