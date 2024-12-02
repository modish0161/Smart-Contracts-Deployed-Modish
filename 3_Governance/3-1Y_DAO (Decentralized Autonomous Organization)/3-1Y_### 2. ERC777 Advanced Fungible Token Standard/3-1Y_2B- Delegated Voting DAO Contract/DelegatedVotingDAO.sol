// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DelegatedVotingDAO is ERC777, Ownable, ReentrancyGuard, Pausable {
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
    mapping(address => address) public delegates;
    mapping(address => uint256) public delegatedVotes;

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

    event DelegateSet(
        address indexed delegator,
        address indexed delegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousVotes,
        uint256 newVotes
    );

    constructor(
        address[] memory defaultOperators,
        string memory name,
        string memory symbol
    ) ERC777(name, symbol, defaultOperators) {}

    function createProposal(
        string memory title,
        string memory description
    ) external nonReentrant whenNotPaused onlyOwner {
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

        uint256 voterBalance = getVotes(msg.sender);
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

        emit ProposalExecuted(proposalId, approved);
    }

    function delegate(address to) external whenNotPaused {
        require(to != msg.sender, "Cannot delegate to self");

        address currentDelegate = delegates[msg.sender];
        uint256 delegatorBalance = balanceOf(msg.sender);

        delegates[msg.sender] = to;

        emit DelegateSet(msg.sender, to);

        if (currentDelegate != address(0)) {
            _moveDelegates(currentDelegate, to, delegatorBalance);
        } else {
            _moveDelegates(address(0), to, delegatorBalance);
        }
    }

    function getVotes(address account) public view returns (uint256) {
        return balanceOf(account).add(delegatedVotes[account]);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepVotes = delegatedVotes[srcRep];
                uint256 newSrcRepVotes = srcRepVotes.sub(amount);
                delegatedVotes[srcRep] = newSrcRepVotes;
                emit DelegateVotesChanged(srcRep, srcRepVotes, newSrcRepVotes);
            }

            if (dstRep != address(0)) {
                uint256 dstRepVotes = delegatedVotes[dstRep];
                uint256 newDstRepVotes = dstRepVotes.add(amount);
                delegatedVotes[dstRep] = newDstRepVotes;
                emit DelegateVotesChanged(dstRep, dstRepVotes, newDstRepVotes);
            }
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        if (from != address(0)) {
            _moveDelegates(delegates[from], delegates[to], amount);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
