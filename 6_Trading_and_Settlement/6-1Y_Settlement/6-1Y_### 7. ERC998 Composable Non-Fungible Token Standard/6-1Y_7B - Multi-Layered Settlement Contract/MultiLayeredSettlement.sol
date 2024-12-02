// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract MultiLayeredSettlement is ERC998TopDown, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    struct Trade {
        address seller;
        address buyer;
        uint256 parentTokenId;
        uint256 price;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;

    event TradeCreated(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 parentTokenId,
        uint256 price
    );

    event TradeExecuted(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 parentTokenId,
        uint256 price
    );

    constructor(string memory _name, string memory _symbol) ERC998TopDown(_name, _symbol) {}

    /**
     * @dev Creates a new trade agreement between buyer and seller.
     * @param tradeId The unique identifier for the trade.
     * @param seller The address of the seller.
     * @param buyer The address of the buyer.
     * @param parentTokenId The ID of the composable parent token being exchanged.
     * @param price The price in wei for the trade.
     */
    function createTrade(
        bytes32 tradeId,
        address seller,
        address buyer,
        uint256 parentTokenId,
        uint256 price
    ) external onlyOwner whenNotPaused {
        require(trades[tradeId].seller == address(0), "Trade already exists");
        require(ownerOf(parentTokenId) == seller, "Seller does not own the token");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            parentTokenId: parentTokenId,
            price: price,
            isSettled: false
        });

        emit TradeCreated(tradeId, seller, buyer, parentTokenId, price);
    }

    /**
     * @dev Executes the trade by transferring the parent token and all its child assets from the seller to the buyer.
     * @param tradeId The unique identifier for the trade.
     */
    function executeTrade(bytes32 tradeId) external nonReentrant whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.seller != address(0), "Trade does not exist");
        require(!trade.isSettled, "Trade already settled");
        require(msg.sender == trade.buyer, "Caller is not the buyer");

        // Transfer payment from buyer to seller
        IERC20 paymentToken = IERC20(owner());
        require(paymentToken.transferFrom(trade.buyer, trade.seller, trade.price), "Payment failed");

        // Transfer the parent token and all child assets from seller to buyer
        safeTransferFrom(trade.seller, trade.buyer, trade.parentTokenId);

        trade.isSettled = true;

        emit TradeExecuted(tradeId, trade.seller, trade.buyer, trade.parentTokenId, trade.price);
    }

    /**
     * @dev Pauses the contract, preventing trade creation and execution.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade creation and execution.
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
