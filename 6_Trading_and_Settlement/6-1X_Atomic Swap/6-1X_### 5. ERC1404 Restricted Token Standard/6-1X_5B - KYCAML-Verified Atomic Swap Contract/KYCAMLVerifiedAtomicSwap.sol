// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

contract KYCAMLVerifiedAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant KYC_VERIFIER_ROLE = keccak256("KYC_VERIFIER_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorToken;
        address participantToken;
        uint256 initiatorAmount;
        uint256 participantAmount;
        bytes32 secretHash;
        bytes32 secret;
        uint256 startTime;
        uint256 timeLockDuration;
        bool isInitiated;
        bool isCompleted;
        bool isRefunded;
    }

    mapping(bytes32 => Swap) public swaps;
    mapping(address => bool) public verifiedParticipants;

    event SwapInitiated(
        bytes32 indexed swapId,
        address indexed initiator,
        address indexed participant,
        address initiatorToken,
        address participantToken,
        uint256 initiatorAmount,
        uint256 participantAmount,
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

    event ParticipantVerified(address indexed participant);
    event ParticipantUnverified(address indexed participant);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KYC_VERIFIER_ROLE, msg.sender);
    }

    /**
     * @dev Verifies a participant for KYC/AML compliance.
     * @param participant The address of the participant to verify.
     */
    function verifyParticipant(address participant) external onlyRole(KYC_VERIFIER_ROLE) {
        verifiedParticipants[participant] = true;
        emit ParticipantVerified(participant);
    }

    /**
     * @dev Revokes the verification of a participant.
     * @param participant The address of the participant to revoke.
     */
    function unverifyParticipant(address participant) external onlyRole(KYC_VERIFIER_ROLE) {
        verifiedParticipants[participant] = false;
        emit ParticipantUnverified(participant);
    }

    /**
     * @dev Initiates a KYC/AML verified token atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC1404 token.
     * @param _participantToken The address of the participant's ERC1404 token.
     * @param _initiatorAmount The amount of the initiator's restricted tokens to be swapped.
     * @param _participantAmount The amount of the participant's restricted tokens to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address _participant,
        address _initiatorToken,
        address _participantToken,
        uint256 _initiatorAmount,
        uint256 _participantAmount,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external whenNotPaused nonReentrant {
        require(verifiedParticipants[msg.sender], "Initiator not verified");
        require(verifiedParticipants[_participant], "Participant not verified");
        require(_initiatorToken != address(0), "Invalid initiator token address");
        require(_participantToken != address(0), "Invalid participant token address");
        require(_initiatorAmount > 0, "Initiator amount must be greater than 0");
        require(_participantAmount > 0, "Participant amount must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorToken: _initiatorToken,
            participantToken: _participantToken,
            initiatorAmount: _initiatorAmount,
            participantAmount: _participantAmount,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        IERC20(_initiatorToken).transferFrom(msg.sender, address(this), _initiatorAmount);

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorToken,
            _participantToken,
            _initiatorAmount,
            _participantAmount,
            _secretHash,
            block.timestamp,
            _timeLockDuration
        );
    }

    /**
     * @dev Completes the KYC/AML verified token atomic swap by revealing the secret.
     * @param _swapId The ID of the swap.
     * @param _secret The secret used to complete the swap.
     */
    function completeSwap(bytes32 _swapId, bytes32 _secret) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            msg.sender == swap.participant,
            "Only participant can complete the swap"
        );
        require(
            keccak256(abi.encodePacked(_secret)) == swap.secretHash,
            "Invalid secret"
        );

        swap.secret = _secret;
        swap.isCompleted = true;

        IERC20(swap.participantToken).transferFrom(
            swap.participant,
            swap.initiator,
            swap.participantAmount
        );

        IERC20(swap.initiatorToken).transfer(
            swap.participant,
            swap.initiatorAmount
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

        IERC20(swap.initiatorToken).transfer(
            swap.initiator,
            swap.initiatorAmount
        );

        emit SwapRefunded(_swapId, swap.initiator);
    }

    /**
     * @dev Adds a KYC/AML verifier.
     * @param verifier The address of the verifier to add.
     */
    function addKYCVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(KYC_VERIFIER_ROLE, verifier);
    }

    /**
     * @dev Removes a KYC/AML verifier.
     * @param verifier The address of the verifier to remove.
     */
    function removeKYCVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(KYC_VERIFIER_ROLE, verifier);
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
}
