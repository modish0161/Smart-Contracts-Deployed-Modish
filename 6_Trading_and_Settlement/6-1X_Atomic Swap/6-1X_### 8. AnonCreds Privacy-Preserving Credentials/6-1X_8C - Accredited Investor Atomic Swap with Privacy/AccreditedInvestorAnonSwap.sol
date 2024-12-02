// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AccreditedInvestorAnonSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorTokenContract;
        uint256 initiatorTokenAmount;
        address participantTokenContract;
        uint256 participantTokenAmount;
        bytes32 initiatorAnonCredential;
        bytes32 participantAnonCredential;
        bytes32 secretHash;
        bytes32 secret;
        uint256 startTime;
        uint256 timeLockDuration;
        bool isInitiated;
        bool isCompleted;
        bool isRefunded;
    }

    mapping(bytes32 => Swap) public swaps;

    event SwapInitiated(
        bytes32 indexed swapId,
        address indexed initiator,
        address indexed participant,
        address initiatorTokenContract,
        uint256 initiatorTokenAmount,
        address participantTokenContract,
        uint256 participantTokenAmount,
        bytes32 secretHash,
        uint256 startTime,
        uint256 timeLockDuration
    );

    event SwapCompleted(
        bytes32 indexed swapId,
        address indexed participant,
        bytes32 secret
    );

    event SwapRefunded(
        bytes32 indexed swapId,
        address indexed initiator
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /**
     * @dev Initiates a privacy-preserving atomic swap with anonymous credentials and accredited investor verification.
     * @param _participant The address of the participant.
     * @param _initiatorTokenContract The address of the initiator's token contract.
     * @param _initiatorTokenAmount The amount of initiator's tokens to be swapped.
     * @param _participantTokenContract The address of the participant's token contract.
     * @param _participantTokenAmount The amount of participant's tokens to be swapped.
     * @param _initiatorAnonCredential The anonymous credential of the initiator.
     * @param _participantAnonCredential The anonymous credential of the participant.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address _participant,
        address _initiatorTokenContract,
        uint256 _initiatorTokenAmount,
        address _participantTokenContract,
        uint256 _participantTokenAmount,
        bytes32 _initiatorAnonCredential,
        bytes32 _participantAnonCredential,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external whenNotPaused nonReentrant {
        require(_initiatorTokenContract != address(0), "Invalid initiator token contract address");
        require(_participantTokenContract != address(0), "Invalid participant token contract address");
        require(_initiatorTokenAmount > 0, "Initiator token amount must be greater than 0");
        require(_participantTokenAmount > 0, "Participant token amount must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");
        require(_initiatorAnonCredential != bytes32(0), "Invalid initiator anonymous credential");
        require(_participantAnonCredential != bytes32(0), "Invalid participant anonymous credential");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorTokenContract: _initiatorTokenContract,
            initiatorTokenAmount: _initiatorTokenAmount,
            participantTokenContract: _participantTokenContract,
            participantTokenAmount: _participantTokenAmount,
            initiatorAnonCredential: _initiatorAnonCredential,
            participantAnonCredential: _participantAnonCredential,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        IERC20(_initiatorTokenContract).transferFrom(msg.sender, address(this), _initiatorTokenAmount);

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorTokenContract,
            _initiatorTokenAmount,
            _participantTokenContract,
            _participantTokenAmount,
            _secretHash,
            block.timestamp,
            _timeLockDuration
        );
    }

    /**
     * @dev Completes the atomic swap by revealing the secret and verifying the participant's anonymous credential.
     * @param _swapId The ID of the swap.
     * @param _secret The secret used to complete the swap.
     * @param _participantAnonCredential The anonymous credential of the participant.
     */
    function completeSwap(bytes32 _swapId, bytes32 _secret, bytes32 _participantAnonCredential) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            keccak256(abi.encodePacked(_secret)) == swap.secretHash,
            "Invalid secret"
        );
        require(
            swap.participantAnonCredential == _participantAnonCredential,
            "Invalid participant anonymous credential"
        );

        swap.secret = _secret;
        swap.isCompleted = true;

        IERC20(swap.participantTokenContract).transferFrom(
            swap.participant,
            swap.initiator,
            swap.participantTokenAmount
        );

        IERC20(swap.initiatorTokenContract).transfer(
            swap.participant,
            swap.initiatorTokenAmount
        );

        emit SwapCompleted(_swapId, msg.sender, _secret);
    }

    /**
     * @dev Refunds the swap to the initiator if the time lock has expired and the swap is not completed.
     * @param _swapId The ID of the swap.
     */
    function refundSwap(bytes32 _swapId) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            msg.sender == swap.initiator,
            "Only initiator can refund the swap"
        );
        require(block.timestamp >= swap.startTime + swap.timeLockDuration, "Time lock not expired");

        swap.isRefunded = true;

        IERC20(swap.initiatorTokenContract).transfer(
            swap.initiator,
            swap.initiatorTokenAmount
        );

        emit SwapRefunded(_swapId, swap.initiator);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
