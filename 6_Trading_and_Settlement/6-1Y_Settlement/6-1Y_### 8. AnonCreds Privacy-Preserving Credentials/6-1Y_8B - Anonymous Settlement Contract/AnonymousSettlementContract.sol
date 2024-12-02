// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AnonymousSettlementContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // Mapping to store the hashed credentials for approved participants
    mapping(bytes32 => bool) private approvedParticipants;

    // Mapping to store the executed trades to prevent double spending
    mapping(bytes32 => bool) private executedTrades;

    // Event emitted when a new participant is added
    event ParticipantApproved(bytes32 indexed participantHash);
    
    // Event emitted when a trade is executed
    event TradeExecuted(
        bytes32 indexed tradeId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint256 price
    );

    constructor() {}

    /**
     * @dev Approves a new participant by storing their hashed credentials.
     * @param participantHash The hashed credentials of the participant.
     */
    function approveParticipant(bytes32 participantHash) external onlyOwner {
        require(!approvedParticipants[participantHash], "Participant already approved");
        approvedParticipants[participantHash] = true;
        emit ParticipantApproved(participantHash);
    }

    /**
     * @dev Executes a trade between two approved participants.
     * @param tradeId The unique identifier for the trade.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param amount The amount of tokens being traded.
     * @param price The price in wei for the trade.
     * @param buyerProof The merkle proof for the buyer's credentials.
     * @param sellerProof The merkle proof for the seller's credentials.
     * @param root The root of the merkle tree for approved participants.
     */
    function executeTrade(
        bytes32 tradeId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 price,
        bytes32[] calldata buyerProof,
        bytes32[] calldata sellerProof,
        bytes32 root
    ) external nonReentrant whenNotPaused {
        require(!executedTrades[tradeId], "Trade already executed");
        require(isApproved(buyer, buyerProof, root), "Buyer not approved");
        require(isApproved(seller, sellerProof, root), "Seller not approved");
        
        // Transfer payment from buyer to seller
        IERC20 paymentToken = IERC20(owner());
        require(paymentToken.transferFrom(buyer, seller, price), "Payment failed");

        // Transfer tokens from seller to buyer
        require(paymentToken.transferFrom(seller, buyer, amount), "Token transfer failed");

        // Mark trade as executed
        executedTrades[tradeId] = true;

        emit TradeExecuted(tradeId, buyer, seller, amount, price);
    }

    /**
     * @dev Checks if the participant is approved using a Merkle proof.
     * @param participant The address of the participant.
     * @param proof The merkle proof for the participant's credentials.
     * @param root The root of the merkle tree for approved participants.
     * @return True if the participant is approved, false otherwise.
     */
    function isApproved(
        address participant,
        bytes32[] calldata proof,
        bytes32 root
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(participant));
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev Pauses the contract, preventing trade execution.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade execution.
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
