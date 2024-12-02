// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiAssetSettlementContract is ERC1155, Ownable, ReentrancyGuard, Pausable {
    // Event emitted when a trade is settled
    event TradeSettled(address indexed seller, address indexed buyer, uint256[] tokenIds, uint256[] amounts, bytes32 tradeId);

    // Structure to hold trade details
    struct Trade {
        address seller;
        address buyer;
        uint256[] tokenIds;
        uint256[] amounts;
        bool isActive;
    }

    // Mapping to hold active trades
    mapping(bytes32 => Trade) public trades;

    // Constructor
    constructor(string memory uri) ERC1155(uri) {}

    /**
     * @dev Creates a new trade between a seller and a buyer for multiple asset types.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param tokenIds Array of token IDs involved in the trade.
     * @param amounts Array of amounts for each token ID.
     * @param tradeId Unique identifier for the trade.
     */
    function createTrade(
        address seller,
        address buyer,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes32 tradeId
    ) external onlyOwner whenNotPaused {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(tokenIds.length == amounts.length, "Token IDs and amounts length mismatch");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            tokenIds: tokenIds,
            amounts: amounts,
            isActive: true
        });
    }

    /**
     * @dev Settles a trade by transferring tokens from the seller to the buyer.
     * @param tradeId Unique identifier for the trade to be settled.
     */
    function settleTrade(bytes32 tradeId) external nonReentrant whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");

        // Ensure the seller has approved this contract to manage the tokens
        require(
            isApprovedForAll(trade.seller, address(this)),
            "Contract not approved to transfer seller's tokens"
        );

        // Transfer the tokens from the seller to the buyer
        safeBatchTransferFrom(trade.seller, trade.buyer, trade.tokenIds, trade.amounts, "");

        // Mark the trade as settled
        trade.isActive = false;

        emit TradeSettled(trade.seller, trade.buyer, trade.tokenIds, trade.amounts, tradeId);
    }

    /**
     * @dev Cancels an active trade.
     * @param tradeId Unique identifier for the trade to be cancelled.
     */
    function cancelTrade(bytes32 tradeId) external whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.seller || msg.sender == owner(), "Only seller or owner can cancel");

        // Mark the trade as cancelled
        trade.isActive = false;
    }

    /**
     * @dev Pauses the contract, preventing any trade settlements.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade settlements.
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
