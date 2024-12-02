// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC1404 is IERC20 {
    function detectTransferRestriction(address from, address to, uint256 value) external view returns (uint8);
    function messageForTransferRestriction(uint8 restrictionCode) external view returns (string memory);
    function canTransfer(address to, uint256 value) external view returns (bool);
}

contract RegulationCompliantSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1404 public restrictedToken;

    event TradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        bytes32 tradeId,
        bool success
    );

    event ComplianceCheckPassed(address indexed participant, bool status);
    event ParticipantVerified(address indexed participant, bool status);

    struct Trade {
        address seller;
        address buyer;
        uint256 value;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;
    mapping(address => bool) public verifiedParticipants;

    modifier onlyVerified() {
        require(verifiedParticipants[msg.sender], "Caller is not verified");
        _;
    }

    constructor(address _restrictedToken) {
        require(_restrictedToken != address(0), "Invalid token address");
        restrictedToken = IERC1404(_restrictedToken);
    }

    /**
     * @dev Verifies a participant to be eligible for trading.
     * @param participant The address to verify.
     */
    function verifyParticipant(address participant) external onlyOwner {
        verifiedParticipants[participant] = true;
        emit ParticipantVerified(participant, true);
    }

    /**
     * @dev Revokes the verification of a participant.
     * @param participant The address to revoke verification.
     */
    function revokeVerification(address participant) external onlyOwner {
        verifiedParticipants[participant] = false;
        emit ParticipantVerified(participant, false);
    }

    /**
     * @dev Creates a trade between a seller and a buyer.
     * @param tradeId Unique identifier for the trade.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param value Amount of tokens to be traded.
     */
    function createTrade(
        bytes32 tradeId,
        address seller,
        address buyer,
        uint256 value
    ) external onlyVerified whenNotPaused nonReentrant {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");
        require(verifiedParticipants[seller] && verifiedParticipants[buyer], "Participants are not verified");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            value: value,
            isSettled: false
        });
    }

    /**
     * @dev Settles a trade if compliance requirements are met.
     * @param tradeId Unique identifier for the trade.
     */
    function settleTrade(bytes32 tradeId) external onlyOwner whenNotPaused nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.seller != address(0) && trade.buyer != address(0), "Trade ID does not exist");
        require(!trade.isSettled, "Trade already settled");

        uint8 restrictionCode = restrictedToken.detectTransferRestriction(trade.seller, trade.buyer, trade.value);
        if (restrictionCode == 0) {
            restrictedToken.transferFrom(trade.seller, trade.buyer, trade.value);
            trade.isSettled = true;
            emit TradeSettled(trade.seller, trade.buyer, trade.value, tradeId, true);
        } else {
            emit TradeSettled(trade.seller, trade.buyer, trade.value, tradeId, false);
        }
    }

    /**
     * @dev Checks compliance status for a participant.
     * @param participant The address to check.
     */
    function checkCompliance(address participant) external view returns (bool) {
        return verifiedParticipants[participant];
    }

    /**
     * @dev Pauses the contract, preventing trade creation and settlements.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade creation and settlements.
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
