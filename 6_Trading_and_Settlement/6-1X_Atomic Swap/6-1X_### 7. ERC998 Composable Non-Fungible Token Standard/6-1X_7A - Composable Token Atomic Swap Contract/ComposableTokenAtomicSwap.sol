// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/IERC998.sol";

contract ComposableTokenAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorTokenContract;
        uint256 initiatorTokenId;
        address participantTokenContract;
        uint256 participantTokenId;
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
        uint256 initiatorTokenId,
        address participantTokenContract,
        uint256 participantTokenId,
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
    }

    /**
     * @dev Initiates an atomic swap between participants using ERC998 composable tokens.
     * @param _participant The address of the participant.
     * @param _initiatorTokenContract The address of the initiator's ERC998 token contract.
     * @param _initiatorTokenId The ID of the initiator's composable token to be swapped.
     * @param _participantTokenContract The address of the participant's ERC998 token contract.
     * @param _participantTokenId The ID of the participant's composable token to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address _participant,
        address _initiatorTokenContract,
        uint256 _initiatorTokenId,
        address _participantTokenContract,
        uint256 _participantTokenId,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external whenNotPaused nonReentrant {
        require(_initiatorTokenContract != address(0), "Invalid initiator token contract address");
        require(_participantTokenContract != address(0), "Invalid participant token contract address");
        require(_initiatorTokenId > 0, "Initiator token ID must be greater than 0");
        require(_participantTokenId > 0, "Participant token ID must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorTokenContract: _initiatorTokenContract,
            initiatorTokenId: _initiatorTokenId,
            participantTokenContract: _participantTokenContract,
            participantTokenId: _participantTokenId,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        IERC721(_initiatorTokenContract).transferFrom(msg.sender, address(this), _initiatorTokenId);

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorTokenContract,
            _initiatorTokenId,
            _participantTokenContract,
            _participantTokenId,
            _secretHash,
            block.timestamp,
            _timeLockDuration
        );
    }

    /**
     * @dev Completes the atomic swap by revealing the secret.
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

        IERC721(swap.participantTokenContract).transferFrom(
            swap.participant,
            swap.initiator,
            swap.participantTokenId
        );

        IERC721(swap.initiatorTokenContract).transfer(
            swap.participant,
            swap.initiatorTokenId
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

        IERC721(swap.initiatorTokenContract).transfer(
            swap.initiator,
            swap.initiatorTokenId
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
}
