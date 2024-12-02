// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AdvancedDAOGovernance is ERC777, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Proposal {
        string title;
        string description;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public operators;

    uint256 public constant VOTING_DURATION = 7 days;

    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        bool approved
    );

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    constructor(
        address[] memory defaultOperators,
        string memory name,
        string memory symbol
    ) ERC777(name, symbol, defaultOperators) {
        for (uint256 i = 0; i < defaultOperators.length; i++) {
            operators[defaultOperators[i]] = true;
            emit OperatorAdded(defaultOperators[i]);
        }
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Caller is not an operator");
        _;
    }

    function createProposal(
        string memory title,
        string memory description
    ) external nonReentrant whenNotPaused onlyOperator {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            title: title,
            description: description,
            endTime: block.timestamp + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, title, description, block.timestamp + VOTING_DURATION);
    }

    function vote(uint256 proposalId, bool support) external nonReentrant whenNotPaused {
        require(block.timestamp < proposals[proposalId].endTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        uint256 voterBalance = balanceOf(msg.sender);
        require(voterBalance > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposals[proposalId].yesVotes = proposals[proposalId].yesVotes.add(voterBalance);
        } else {
            proposals[proposalId].noVotes = proposals[proposalId].noVotes.add(voterBalance);
        }

        emit VoteCasted(proposalId, msg.sender, support, voterBalance);
    }

    function executeProposal(uint256 proposalId) external nonReentrant onlyOperator {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        bool approved = proposal.yesVotes > proposal.noVotes;

        emit ProposalExecuted(proposalId, approved);
    }

    function addOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Invalid operator address");
        operators[newOperator] = true;
        emit OperatorAdded(newOperator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(operators[operator], "Address is not an operator");
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
