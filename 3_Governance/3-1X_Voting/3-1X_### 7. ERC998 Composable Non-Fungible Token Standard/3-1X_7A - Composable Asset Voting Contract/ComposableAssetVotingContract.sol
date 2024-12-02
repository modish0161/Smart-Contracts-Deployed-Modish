// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998ERC721TopDown.sol";

contract ComposableAssetVotingContract is Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 deadline;
        bool executed;
        uint256 quorumRequired;
        uint256 approvalPercentageRequired;
        address[] affectedAssets;
        bytes[] executionData;
    }

    // ERC998 Composable Token Interface
    ERC998ERC721TopDown public composableToken;

    // Mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Proposal ID counter
    Counters.Counter private proposalCounter;

    // Mapping to track if a user has voted on a proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Whitelisted addresses for voting
    EnumerableSet.AddressSet private whitelistedAddresses;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        string description,
        uint256 quorumRequired,
        uint256 approvalPercentageRequired,
        uint256 deadline
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint256 voteType);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event WhitelistUpdated(address indexed account, bool status);

    // Constructor
    constructor(ERC998ERC721TopDown _composableToken) {
        composableToken = _composableToken;
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
        uint256 _approvalPercentageRequired,
        address[] calldata _affectedAssets,
        bytes[] calldata _executionData
    ) external onlyOwner {
        require(_quorumRequired > 0 && _quorumRequired <= 100, "Invalid quorum");
        require(_approvalPercentageRequired > 0 && _approvalPercentageRequired <= 100, "Invalid approval percentage");

        uint256 proposalId = proposalCounter.current();
        proposalCounter.increment();

        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            voteCount: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            executed: false,
            deadline: block.timestamp + 7 days, // Default voting period of 7 days
            quorumRequired: _quorumRequired,
            approvalPercentageRequired: _approvalPercentageRequired,
            affectedAssets: _affectedAssets,
            executionData: _executionData
        });

        emit ProposalCreated(
            proposalId,
            _title,
            _description,
            _quorumRequired,
            _approvalPercentageRequired,
            block.timestamp + 7 days
        );
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, uint8 _voteType) external onlyWhitelisted nonReentrant {
        require(_voteType >= 1 && _voteType <= 3, "Invalid vote type"); // 1 = Yes, 2 = No, 3 = Abstain
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp <= proposal.deadline, "Voting period over");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 weight = composableToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        proposal.voteCount += 1;
        hasVoted[_proposalId][msg.sender] = true;

        if (_voteType == 1) {
            proposal.yesVotes += weight;
        } else if (_voteType == 2) {
            proposal.noVotes += weight;
        } else if (_voteType == 3) {
            proposal.abstainVotes += weight;
        }

        emit VoteCast(msg.sender, _proposalId, _voteType);
    }

    // Function to execute a proposal
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant {
        Proposal storage proposal = proposals[_proposalId];

        require(block.timestamp > proposal.deadline, "Voting period not over");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalSupply = composableToken.totalSupply();
        uint256 requiredQuorum = (totalSupply * proposal.quorumRequired) / 100;
        uint256 approvalPercentage = (proposal.yesVotes * 100) / (proposal.yesVotes + proposal.noVotes);

        bool quorumReached = proposal.yesVotes >= requiredQuorum;
        bool approved = approvalPercentage >= proposal.approvalPercentageRequired;

        if (quorumReached && approved) {
            proposal.executed = true;
            bool success = true;
            for (uint256 i = 0; i < proposal.executionData.length; i++) {
                (bool callSuccess,) = address(proposal.affectedAssets[i]).call(proposal.executionData[i]);
                if (!callSuccess) success = false;
            }
            emit ProposalExecuted(_proposalId, success);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
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
            uint256 yesVotes,
            uint256 noVotes,
            uint256 abstainVotes,
            bool executed,
            uint256 deadline,
            uint256 quorumRequired,
            uint256 approvalPercentageRequired,
            address[] memory affectedAssets
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.abstainVotes,
            proposal.executed,
            proposal.deadline,
            proposal.quorumRequired,
            proposal.approvalPercentageRequired,
            proposal.affectedAssets
        );
    }

    // Function to get the total number of proposals
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter.current();
    }
}
