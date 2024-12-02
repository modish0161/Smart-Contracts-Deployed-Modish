// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicAtomicSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Swap {
        address initiator;
        address participant;
        address initiatorToken;
        address participantToken;
        uint256 initiatorAmount;
        uint256 participantAmount;
        bytes32 secretHash;
        bytes32 secret;
        bool isInitiated;
        bool isCompleted;
    }

    mapping(bytes32 => Swap) public swaps;

    event SwapInitiated(
        bytes32 indexed swapId,
        address indexed initiator,
        address indexed participant,
        address initiatorToken,
        address participantToken,
        uint256 initiatorAmount,
        uint256 participantAmount,
        bytes32 secretHash
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

    /**
     * @dev Initiates a new atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC20 token.
     * @param _participantToken The address of the participant's ERC20 token.
     * @param _initiatorAmount The amount of the initiator's token to be swapped.
     * @param _participantAmount The amount of the participant's token to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     */
    function initiateSwap(
        address _participant,
        address _initiatorToken,
        address _participantToken,
        uint256 _initiatorAmount,
        uint256 _participantAmount,
        bytes32 _secretHash
    ) external nonReentrant {
        require(_participant != address(0), "Invalid participant address");
        require(_initiatorToken != address(0), "Invalid initiator token address");
        require(_participantToken != address(0), "Invalid participant token address");
        require(_initiatorAmount > 0, "Initiator amount must be greater than 0");
        require(_participantAmount > 0, "Participant amount must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");

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
            isInitiated: true,
            isCompleted: false
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
            _secretHash
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
        require(msg.sender == swap.participant, "Only participant can complete the swap");
        require(keccak256(abi.encodePacked(_secret)) == swap.secretHash, "Invalid secret");

        swap.secret = _secret;
        swap.isCompleted = true;

        IERC20(swap.participantToken).transferFrom(swap.participant, swap.initiator, swap.participantAmount);
        IERC20(swap.initiatorToken).transfer(swap.participant, swap.initiatorAmount);

        emit SwapCompleted(_swapId, msg.sender, _secret);
    }

    /**
     * @dev Refunds the swap to the initiator if it hasn't been completed.
     * @param _swapId The ID of the swap.
     */
    function refundSwap(bytes32 _swapId) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(msg.sender == swap.initiator, "Only initiator can refund the swap");

        swap.isCompleted = true;

        IERC20(swap.initiatorToken).transfer(swap.initiator, swap.initiatorAmount);

        emit SwapRefunded(_swapId, msg.sender);
    }
}
