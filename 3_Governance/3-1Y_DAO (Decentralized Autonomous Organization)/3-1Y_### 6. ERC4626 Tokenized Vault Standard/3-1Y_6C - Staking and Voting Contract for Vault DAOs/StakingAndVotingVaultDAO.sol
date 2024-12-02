// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingAndVotingVaultDAO is ERC4626, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Struct to define a governance proposal
    struct Proposal {
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved;
    }

    IERC20 public governanceToken; // Governance token for staking and voting
    uint256 public proposalCount;
    uint256 public votingDuration; // Duration of the voting period
    uint256 public minimumStakeAmount; // Minimum stake required to create a proposal
    uint256 public totalStaked; // Total tokens staked in the contract

    mapping(address => uint256) public stakedBalances;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(
        uint256 indexed proposalId,
        string description,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        bool vote,
        uint256 weight
    );

    event ProposalExecuted(
        uint256 indexed proposalId,
        bool success
    );

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _governanceToken,
        uint256 _votingDuration,
        uint256 _minimumStakeAmount
    ) ERC4626(IERC20(_asset)) ERC20(_name, _symbol) {
        governanceToken = IERC20(_governanceToken);
        votingDuration = _votingDuration;
        minimumStakeAmount = _minimumStakeAmount;
    }

    // Modifier to check if the sender has staked enough tokens
    modifier hasStakedEnough(address account) {
        require(stakedBalances[account] >= minimumStakeAmount, "Insufficient staked balance");
        _;
    }

    // Function to stake governance tokens
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");

        governanceToken.transferFrom(msg.sender, address(this), amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);

        emit Staked(msg.sender, amount);
    }

    // Function to unstake governance tokens
    function unstake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalances[msg.sender] >= amount, "Insufficient staked balance");

        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        governanceToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    // Function to create a new governance proposal
    function createProposal(string memory description) external hasStakedEnough(msg.sender) whenNotPaused {
        uint256 proposalId = proposalCount;
        proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingDuration;

        emit ProposalCreated(proposalId, description, proposal.startTime, proposal.endTime);
    }

    // Function to vote on a proposal
    function vote(uint256 proposalId, bool support) external hasStakedEnough(msg.sender) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 weight = stakedBalances[msg.sender];
        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.forVotes = proposal.forVotes.add(weight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(weight);
        }

        emit VoteCasted(proposalId, msg.sender, support, weight);
    }

    // Function to execute a proposal after the voting period ends
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

    // Function to set the minimum stake amount for creating proposals
    function setMinimumStakeAmount(uint256 _minimumStakeAmount) external onlyOwner {
        minimumStakeAmount = _minimumStakeAmount;
    }

    // Function to set the voting duration for proposals
    function setVotingDuration(uint256 _votingDuration) external onlyOwner {
        votingDuration = _votingDuration;
    }

    // Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
