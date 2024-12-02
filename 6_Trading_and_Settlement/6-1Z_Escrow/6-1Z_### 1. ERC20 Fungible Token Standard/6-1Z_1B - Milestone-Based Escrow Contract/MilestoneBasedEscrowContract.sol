// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MilestoneBasedEscrowContract is Ownable, ReentrancyGuard {
    // Events
    event MilestoneCreated(uint256 indexed milestoneId, uint256 amount, uint256 releaseTime);
    event MilestoneCompleted(uint256 indexed milestoneId, address indexed beneficiary, uint256 amount);
    event FundsRefunded(address indexed depositor, uint256 amount);
    event ContractTerminated(address indexed depositor, uint256 remainingFunds);

    // Struct to hold details of each milestone
    struct Milestone {
        uint256 amount;           // Amount of ERC20 tokens allocated to this milestone
        uint256 releaseTime;      // Time when the milestone can be released
        bool isReleased;          // Flag to check if the milestone has been released
    }

    // ERC20 token used for escrow
    IERC20 public escrowToken;

    // Address of the depositor
    address public depositor;

    // Address of the beneficiary
    address public beneficiary;

    // Total number of milestones
    uint256 public milestoneCount;

    // Mapping from milestone ID to Milestone details
    mapping(uint256 => Milestone) public milestones;

    // Total funds deposited in the contract
    uint256 public totalDeposited;

    // Modifier to check if the caller is the depositor
    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    // Modifier to check if the caller is the beneficiary
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
        _;
    }

    // Modifier to check if the milestone can be released
    modifier canRelease(uint256 _milestoneId) {
        require(_milestoneId < milestoneCount, "Milestone does not exist");
        require(block.timestamp >= milestones[_milestoneId].releaseTime, "Milestone release time not reached");
        require(!milestones[_milestoneId].isReleased, "Milestone already released");
        _;
    }

    constructor(address _depositor, address _beneficiary, IERC20 _tokenAddress) {
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");

        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowToken = _tokenAddress;
    }

    /**
     * @dev Deposit funds into the escrow contract.
     * @param _amount The amount of ERC20 tokens to deposit.
     */
    function depositFunds(uint256 _amount) external onlyDepositor nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(escrowToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        totalDeposited += _amount;
    }

    /**
     * @dev Create a milestone for fund release.
     * @param _amount The amount of ERC20 tokens allocated to the milestone.
     * @param _releaseTime The time when the milestone can be released.
     */
    function createMilestone(uint256 _amount, uint256 _releaseTime) external onlyDepositor {
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        require(totalDeposited >= _amount, "Insufficient deposited funds");

        milestones[milestoneCount] = Milestone({
            amount: _amount,
            releaseTime: _releaseTime,
            isReleased: false
        });

        totalDeposited -= _amount;
        milestoneCount++;

        emit MilestoneCreated(milestoneCount - 1, _amount, _releaseTime);
    }

    /**
     * @dev Release funds for a completed milestone.
     * @param _milestoneId The ID of the milestone to release.
     */
    function releaseMilestone(uint256 _milestoneId) external onlyBeneficiary canRelease(_milestoneId) nonReentrant {
        Milestone storage milestone = milestones[_milestoneId];
        milestone.isReleased = true;

        require(escrowToken.transfer(beneficiary, milestone.amount), "Token transfer failed");

        emit MilestoneCompleted(_milestoneId, beneficiary, milestone.amount);
    }

    /**
     * @dev Refund remaining funds to the depositor if the contract is terminated.
     */
    function refundFunds() external onlyDepositor nonReentrant {
        uint256 remainingFunds = escrowToken.balanceOf(address(this));
        require(remainingFunds > 0, "No funds to refund");

        require(escrowToken.transfer(depositor, remainingFunds), "Token transfer failed");

        emit FundsRefunded(depositor, remainingFunds);
    }

    /**
     * @dev Terminate the contract and refund remaining funds to the depositor.
     */
    function terminateContract() external onlyDepositor nonReentrant {
        uint256 remainingFunds = escrowToken.balanceOf(address(this));
        require(remainingFunds > 0, "No funds to terminate");

        for (uint256 i = 0; i < milestoneCount; i++) {
            require(milestones[i].isReleased, "All milestones must be completed before termination");
        }

        require(escrowToken.transfer(depositor, remainingFunds), "Token transfer failed");
        emit ContractTerminated(depositor, remainingFunds);
        selfdestruct(payable(depositor));
    }
}
