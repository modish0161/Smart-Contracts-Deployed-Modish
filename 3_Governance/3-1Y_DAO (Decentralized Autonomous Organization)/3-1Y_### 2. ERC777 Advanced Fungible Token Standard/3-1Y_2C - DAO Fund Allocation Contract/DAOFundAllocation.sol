// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DAOFundAllocation is ERC777, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Proposal {
        string description;
        uint256 amount;
        address payable recipient;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public allocatedFunds;

    uint256 public constant VOTING_DURATION = 7 days;
    uint256 public totalAllocatedFunds;

    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        uint256 amount,
        address recipient,
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

    constructor(
        address[] memory defaultOperators,
        string memory name,
        string memory symbol
    ) ERC777(name, symbol, defaultOperators) {}

    function createProposal(
        string memory description,
        uint256 amount,
        address payable recipient
    ) external nonReentrant whenNotPaused onlyOwner {
        require(amount <= balanceOf(address(this)), "Insufficient funds in DAO");

        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();

        proposals[proposalId] = Proposal({
            description: description,
            amount: amount,
            recipient: recipient,
            endTime: block.timestamp + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit ProposalCreated(proposalId, description, amount, recipient, block.timestamp + VOTING_DURATION);
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

    function executeProposal(uint256 proposalId) external nonReentrant onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        bool approved = proposal.yesVotes > proposal.noVotes;

        if (approved) {
            require(proposal.amount <= balanceOf(address(this)), "Insufficient funds in DAO");
            allocatedFunds[proposal.recipient] = allocatedFunds[proposal.recipient].add(proposal.amount);
            totalAllocatedFunds = totalAllocatedFunds.add(proposal.amount);

            (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
            require(success, "Transfer failed");
        }

        emit ProposalExecuted(proposalId, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        // Custom logic can be added here for further checks
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Accept ETH deposits
    receive() external payable {}
}
