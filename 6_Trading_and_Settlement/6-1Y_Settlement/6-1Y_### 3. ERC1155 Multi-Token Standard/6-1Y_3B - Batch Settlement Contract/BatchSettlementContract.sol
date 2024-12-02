// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BatchSettlementContract is ERC1155, Ownable, ReentrancyGuard, Pausable, ERC1155Supply {
    // Event emitted when a batch trade is settled
    event BatchTradeSettled(address indexed seller, address indexed buyer, uint256[] tokenIds, uint256[] amounts, bytes32 batchId);

    // Structure to hold batch trade details
    struct BatchTrade {
        address seller;
        address buyer;
        uint256[] tokenIds;
        uint256[] amounts;
        bool isActive;
    }

    // Mapping to hold active batch trades
    mapping(bytes32 => BatchTrade) public batchTrades;

    // Constructor
    constructor(string memory uri) ERC1155(uri) {}

    /**
     * @dev Creates a new batch trade between a seller and a buyer for multiple asset types.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param tokenIds Array of token IDs involved in the batch trade.
     * @param amounts Array of amounts for each token ID.
     * @param batchId Unique identifier for the batch trade.
     */
    function createBatchTrade(
        address seller,
        address buyer,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes32 batchId
    ) external onlyOwner whenNotPaused {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(tokenIds.length == amounts.length, "Token IDs and amounts length mismatch");
        require(batchTrades[batchId].seller == address(0), "Batch ID already exists");

        batchTrades[batchId] = BatchTrade({
            seller: seller,
            buyer: buyer,
            tokenIds: tokenIds,
            amounts: amounts,
            isActive: true
        });
    }

    /**
     * @dev Settles a batch trade by transferring tokens from the seller to the buyer.
     * @param batchId Unique identifier for the batch trade to be settled.
     */
    function settleBatchTrade(bytes32 batchId) external nonReentrant whenNotPaused {
        BatchTrade storage batchTrade = batchTrades[batchId];
        require(batchTrade.isActive, "Batch trade is not active");

        // Ensure the seller has approved this contract to manage the tokens
        require(
            isApprovedForAll(batchTrade.seller, address(this)),
            "Contract not approved to transfer seller's tokens"
        );

        // Transfer the tokens from the seller to the buyer
        safeBatchTransferFrom(batchTrade.seller, batchTrade.buyer, batchTrade.tokenIds, batchTrade.amounts, "");

        // Mark the batch trade as settled
        batchTrade.isActive = false;

        emit BatchTradeSettled(batchTrade.seller, batchTrade.buyer, batchTrade.tokenIds, batchTrade.amounts, batchId);
    }

    /**
     * @dev Cancels an active batch trade.
     * @param batchId Unique identifier for the batch trade to be cancelled.
     */
    function cancelBatchTrade(bytes32 batchId) external whenNotPaused {
        BatchTrade storage batchTrade = batchTrades[batchId];
        require(batchTrade.isActive, "Batch trade is not active");
        require(msg.sender == batchTrade.seller || msg.sender == owner(), "Only seller or owner can cancel");

        // Mark the batch trade as cancelled
        batchTrade.isActive = false;
    }

    /**
     * @dev Pauses the contract, preventing any batch trade settlements.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing batch trade settlements.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Override ERC1155Receiver to accept transfers.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Override ERC1155Receiver to accept batch transfers.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
