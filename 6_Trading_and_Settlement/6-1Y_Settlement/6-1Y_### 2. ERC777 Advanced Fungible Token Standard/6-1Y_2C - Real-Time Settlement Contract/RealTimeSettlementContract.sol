// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract RealTimeSettlementContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // ERC777 interface identifiers
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    // Events
    event TradeSettled(address indexed buyer, address indexed seller, address token, uint256 amount, bytes32 tradeId);
    event TradeCancelled(address indexed party, bytes32 tradeId);

    // Structure to hold trade details
    struct Trade {
        address buyer;
        address seller;
        address token;
        uint256 amount;
        bool isBuyerFunded;
        bool isSellerFunded;
        bool isActive;
    }

    // Mapping to hold trades
    mapping(bytes32 => Trade) public trades;

    // Constructor
    constructor() {
        // Register the contract as an ERC777 recipient and sender
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _erc1820.setInterfaceImplementer(address(this), TOKENS_SENDER_INTERFACE_HASH, address(this));
    }

    /**
     * @dev Creates a new trade.
     * @param buyer Address of the buyer.
     * @param seller Address of the seller.
     * @param token Address of the ERC777 token to be used for settlement.
     * @param amount Amount of tokens to be settled.
     * @param tradeId Unique identifier for the trade.
     */
    function createTrade(address buyer, address seller, address token, uint256 amount, bytes32 tradeId) external onlyOwner whenNotPaused {
        require(buyer != address(0) && seller != address(0), "Buyer and seller cannot be zero addresses");
        require(amount > 0, "Amount must be greater than zero");
        require(trades[tradeId].buyer == address(0), "Trade ID already exists");

        trades[tradeId] = Trade({
            buyer: buyer,
            seller: seller,
            token: token,
            amount: amount,
            isBuyerFunded: false,
            isSellerFunded: false,
            isActive: true
        });
    }

    /**
     * @dev Handles the reception of ERC777 tokens.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override whenNotPaused {
        require(trades[keccak256(userData)].isActive, "Trade is not active");
        bytes32 tradeId = keccak256(userData);
        Trade storage trade = trades[tradeId];

        require(trade.token == msg.sender, "Token mismatch");
        require(amount == trade.amount, "Incorrect token amount");

        if (from == trade.buyer) {
            require(!trade.isBuyerFunded, "Buyer already funded");
            trade.isBuyerFunded = true;
        } else if (from == trade.seller) {
            require(!trade.isSellerFunded, "Seller already funded");
            trade.isSellerFunded = true;
        } else {
            revert("Invalid funding source");
        }

        // Check if both parties have funded the trade
        if (trade.isBuyerFunded && trade.isSellerFunded) {
            _settleTrade(tradeId);
        }
    }

    /**
     * @dev Internal function to settle a trade.
     * @param tradeId Unique identifier for the trade to be settled.
     */
    function _settleTrade(bytes32 tradeId) internal nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.isBuyerFunded && trade.isSellerFunded, "Both parties must fund the trade");

        // Transfer tokens between buyer and seller
        IERC777(trade.token).send(trade.seller, trade.amount, "");
        IERC777(trade.token).send(trade.buyer, trade.amount, "");

        // Mark trade as settled
        trade.isActive = false;

        emit TradeSettled(trade.buyer, trade.seller, trade.token, trade.amount, tradeId);
    }

    /**
     * @dev Cancels a trade.
     * @param tradeId Unique identifier for the trade to be cancelled.
     */
    function cancelTrade(bytes32 tradeId) external whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.buyer || msg.sender == trade.seller || msg.sender == owner(), "Caller is not authorized to cancel trade");

        // Mark trade as cancelled
        trade.isActive = false;

        // Refund tokens to participants if they have already funded
        if (trade.isBuyerFunded) {
            IERC777(trade.token).send(trade.buyer, trade.amount, "");
        }
        if (trade.isSellerFunded) {
            IERC777(trade.token).send(trade.seller, trade.amount, "");
        }

        emit TradeCancelled(msg.sender, tradeId);
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
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }

    /**
     * @dev Function to handle ERC777 tokens sent from the contract.
     * Required by the ERC777 standard.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called when tokens are sent from this contract.
        // Implement any necessary logic here, e.g., logging or processing the transfer.
    }
}
