// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract VaultTokenAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorVault;
        address participantVault;
        uint256 initiatorShares;
        uint256 participantShares;
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
        address initiatorVault,
        address participantVault,
        uint256 initiatorShares,
        uint256 participantShares,
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
     * @dev Initiates an atomic swap between participants using ERC4626 vault tokens.
     * @param _participant The address of the participant.
     * @param _initiatorVault The address of the initiator's ERC4626 vault.
     * @param _participantVault The address of the participant's ERC4626 vault.
     * @param _initiatorShares The amount of the initiator's vault shares to be swapped.
     * @param _participantShares The amount of the participant's vault shares to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address _participant,
        address _initiatorVault,
        address _participantVault,
        uint256 _initiatorShares,
        uint256 _participantShares,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external whenNotPaused nonReentrant {
        require(_initiatorVault != address(0), "Invalid initiator vault address");
        require(_participantVault != address(0), "Invalid participant vault address");
        require(_initiatorShares > 0, "Initiator shares must be greater than 0");
        require(_participantShares > 0, "Participant shares must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorVault: _initiatorVault,
            participantVault: _participantVault,
            initiatorShares: _initiatorShares,
            participantShares: _participantShares,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        IERC4626(_initiatorVault).transferFrom(msg.sender, address(this), _initiatorShares);

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorVault,
            _participantVault,
            _initiatorShares,
            _participantShares,
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

        IERC4626(swap.participantVault).transferFrom(
            swap.participant,
            swap.initiator,
            swap.participantShares
        );

        IERC4626(swap.initiatorVault).transfer(
            swap.participant,
            swap.initiatorShares
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

        IERC4626(swap.initiatorVault).transfer(
            swap.initiator,
            swap.initiatorShares
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
