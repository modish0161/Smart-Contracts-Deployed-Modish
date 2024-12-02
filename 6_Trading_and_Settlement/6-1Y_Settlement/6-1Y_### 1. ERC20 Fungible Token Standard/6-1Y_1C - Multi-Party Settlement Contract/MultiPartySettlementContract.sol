// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiPartySettlementContract is Ownable, ReentrancyGuard, Pausable {
    struct Settlement {
        address[] participants;
        address[] tokens;
        uint256[] amounts;
        uint256 expirationTime;
        bool isExecuted;
    }

    mapping(bytes32 => Settlement) public settlements;

    event SettlementInitiated(
        bytes32 indexed settlementId,
        address[] participants,
        address[] tokens,
        uint256[] amounts,
        uint256 expirationTime
    );

    event SettlementExecuted(
        bytes32 indexed settlementId,
        address[] participants
    );

    event SettlementCancelled(
        bytes32 indexed settlementId,
        address[] participants
    );

    event SettlementExpired(
        bytes32 indexed settlementId,
        address[] participants
    );

    /**
     * @dev Initiates a multi-party settlement.
     * @param _participants The addresses of all parties involved in the settlement.
     * @param _tokens The ERC20 token contract addresses being used in the settlement.
     * @param _amounts The amounts of each token to be transferred.
     * @param _expirationTime The time by which the settlement must be executed.
     */
    function initiateSettlement(
        address[] calldata _participants,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _expirationTime
    ) external whenNotPaused nonReentrant returns (bytes32 settlementId) {
        require(_participants.length == _tokens.length, "Participants and tokens count mismatch");
        require(_tokens.length == _amounts.length, "Tokens and amounts count mismatch");
        require(_participants.length > 1, "Must involve multiple participants");
        require(_expirationTime > block.timestamp, "Expiration time must be in the future");

        settlementId = keccak256(
            abi.encodePacked(_participants, _tokens, _amounts, _expirationTime, block.timestamp)
        );

        settlements[settlementId] = Settlement({
            participants: _participants,
            tokens: _tokens,
            amounts: _amounts,
            expirationTime: _expirationTime,
            isExecuted: false
        });

        emit SettlementInitiated(settlementId, _participants, _tokens, _amounts, _expirationTime);
    }

    /**
     * @dev Executes the settlement if all participants have approved the contract to transfer their respective tokens before the expiration time.
     * @param _settlementId The unique identifier of the settlement.
     */
    function executeSettlement(bytes32 _settlementId) external nonReentrant {
        Settlement storage settlement = settlements[_settlementId];
        require(!settlement.isExecuted, "Settlement already executed");
        require(settlement.expirationTime > block.timestamp, "Settlement has expired");

        for (uint256 i = 0; i < settlement.participants.length; i++) {
            require(
                IERC20(settlement.tokens[i]).transferFrom(
                    settlement.participants[i],
                    address(this),
                    settlement.amounts[i]
                ),
                "Token transfer to contract failed"
            );
        }

        for (uint256 i = 0; i < settlement.participants.length; i++) {
            require(
                IERC20(settlement.tokens[i]).transfer(
                    settlement.participants[(i + 1) % settlement.participants.length],
                    settlement.amounts[i]
                ),
                "Token transfer to participant failed"
            );
        }

        settlement.isExecuted = true;

        emit SettlementExecuted(_settlementId, settlement.participants);
    }

    /**
     * @dev Cancels a settlement if it has not been executed and the caller is one of the participants.
     * @param _settlementId The unique identifier of the settlement.
     */
    function cancelSettlement(bytes32 _settlementId) external nonReentrant {
        Settlement storage settlement = settlements[_settlementId];
        require(!settlement.isExecuted, "Settlement already executed");
        bool isParticipant = false;
        for (uint256 i = 0; i < settlement.participants.length; i++) {
            if (msg.sender == settlement.participants[i]) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "Not a participant in the settlement");

        delete settlements[_settlementId];

        emit SettlementCancelled(_settlementId, settlement.participants);
    }

    /**
     * @dev Reverses a settlement if it has not been executed and the expiration time has passed.
     * @param _settlementId The unique identifier of the settlement.
     */
    function expireSettlement(bytes32 _settlementId) external nonReentrant {
        Settlement storage settlement = settlements[_settlementId];
        require(!settlement.isExecuted, "Settlement already executed");
        require(settlement.expirationTime <= block.timestamp, "Settlement has not expired yet");

        delete settlements[_settlementId];

        emit SettlementExpired(_settlementId, settlement.participants);
    }

    /**
     * @dev Pauses the contract, preventing new settlements from being initiated.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing new settlements to be initiated.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
