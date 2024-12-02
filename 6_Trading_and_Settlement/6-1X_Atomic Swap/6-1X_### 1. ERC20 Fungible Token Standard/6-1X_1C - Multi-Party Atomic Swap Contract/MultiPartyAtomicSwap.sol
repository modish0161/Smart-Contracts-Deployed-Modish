// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiPartyAtomicSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Swap {
        address[] participants;
        address[] tokens;
        uint256[] amounts;
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
        address[] participants,
        address[] tokens,
        uint256[] amounts,
        bytes32 secretHash,
        uint256 startTime,
        uint256 timeLockDuration
    );

    event SwapCompleted(
        bytes32 indexed swapId,
        address[] participants,
        bytes32 secret
    );

    event SwapRefunded(
        bytes32 indexed swapId,
        address[] participants
    );

    /**
     * @dev Initiates a new multi-party atomic swap.
     * @param _participants The addresses of the participants.
     * @param _tokens The addresses of the ERC20 tokens to be swapped.
     * @param _amounts The amounts of the tokens to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address[] memory _participants,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external nonReentrant {
        require(_participants.length > 1, "Invalid number of participants");
        require(_participants.length == _tokens.length, "Participants and tokens length mismatch");
        require(_tokens.length == _amounts.length, "Tokens and amounts length mismatch");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

        for (uint256 i = 0; i < _participants.length; i++) {
            require(_participants[i] != address(0), "Invalid participant address");
            require(_tokens[i] != address(0), "Invalid token address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
        }

        bytes32 swapId = keccak256(
            abi.encodePacked(_participants, _tokens, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            participants: _participants,
            tokens: _tokens,
            amounts: _amounts,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        for (uint256 i = 0; i < _participants.length; i++) {
            IERC20(_tokens[i]).transferFrom(_participants[i], address(this), _amounts[i]);
        }

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participants,
            _tokens,
            _amounts,
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
        require(keccak256(abi.encodePacked(_secret)) == swap.secretHash, "Invalid secret");

        swap.secret = _secret;
        swap.isCompleted = true;

        for (uint256 i = 0; i < swap.participants.length; i++) {
            IERC20(swap.tokens[i]).transfer(swap.participants[(i + 1) % swap.participants.length], swap.amounts[i]);
        }

        emit SwapCompleted(_swapId, swap.participants, _secret);
    }

    /**
     * @dev Refunds the swap to the participants if the time lock has expired and the swap is not completed.
     * @param _swapId The ID of the swap.
     */
    function refundSwap(bytes32 _swapId) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(block.timestamp >= swap.startTime.add(swap.timeLockDuration), "Time lock not expired");

        swap.isRefunded = true;

        for (uint256 i = 0; i < swap.participants.length; i++) {
            IERC20(swap.tokens[i]).transfer(swap.participants[i], swap.amounts[i]);
        }

        emit SwapRefunded(_swapId, swap.participants);
    }
}
