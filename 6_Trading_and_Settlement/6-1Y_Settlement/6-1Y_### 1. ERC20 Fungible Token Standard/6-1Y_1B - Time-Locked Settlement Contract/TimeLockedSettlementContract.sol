// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TimeLockedSettlementContract is Ownable, ReentrancyGuard, Pausable {
    struct Trade {
        address seller;
        address buyer;
        address sellerToken;
        uint256 sellerAmount;
        address buyerToken;
        uint256 buyerAmount;
        uint256 expirationTime;
        bool isExecuted;
    }

    mapping(bytes32 => Trade) public trades;

    event TradeInitiated(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        address sellerToken,
        uint256 sellerAmount,
        address buyerToken,
        uint256 buyerAmount,
        uint256 expirationTime
    );

    event TradeExecuted(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer
    );

    event TradeCancelled(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer
    );

    event TradeReversed(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer
    );

    /**
     * @dev Initiates a trade between a seller and a buyer with specified token amounts and expiration time.
     * @param _seller The address of the seller.
     * @param _buyer The address of the buyer.
     * @param _sellerToken The address of the seller's token contract.
     * @param _sellerAmount The amount of tokens the seller wants to trade.
     * @param _buyerToken The address of the buyer's token contract.
     * @param _buyerAmount The amount of tokens the buyer wants to trade.
     * @param _expirationTime The time by which the trade must be executed.
     */
    function initiateTrade(
        address _seller,
        address _buyer,
        address _sellerToken,
        uint256 _sellerAmount,
        address _buyerToken,
        uint256 _buyerAmount,
        uint256 _expirationTime
    ) external whenNotPaused nonReentrant returns (bytes32 tradeId) {
        require(_seller != address(0), "Seller address cannot be zero");
        require(_buyer != address(0), "Buyer address cannot be zero");
        require(_sellerToken != address(0), "Seller token address cannot be zero");
        require(_buyerToken != address(0), "Buyer token address cannot be zero");
        require(_sellerAmount > 0, "Seller amount must be greater than zero");
        require(_buyerAmount > 0, "Buyer amount must be greater than zero");
        require(_expirationTime > block.timestamp, "Expiration time must be in the future");

        tradeId = keccak256(
            abi.encodePacked(_seller, _buyer, _sellerToken, _buyerToken, _sellerAmount, _buyerAmount, _expirationTime, block.timestamp)
        );

        trades[tradeId] = Trade({
            seller: _seller,
            buyer: _buyer,
            sellerToken: _sellerToken,
            sellerAmount: _sellerAmount,
            buyerToken: _buyerToken,
            buyerAmount: _buyerAmount,
            expirationTime: _expirationTime,
            isExecuted: false
        });

        emit TradeInitiated(tradeId, _seller, _buyer, _sellerToken, _sellerAmount, _buyerToken, _buyerAmount, _expirationTime);
    }

    /**
     * @dev Executes the trade if both parties have approved the contract to transfer their respective tokens before the expiration time.
     * @param _tradeId The unique identifier of the trade.
     */
    function executeTrade(bytes32 _tradeId) external nonReentrant {
        Trade storage trade = trades[_tradeId];
        require(!trade.isExecuted, "Trade already executed");
        require(trade.expirationTime > block.timestamp, "Trade has expired");
        require(trade.seller != address(0) && trade.buyer != address(0), "Invalid trade");

        // Transfer tokens from seller to buyer
        require(
            IERC20(trade.sellerToken).transferFrom(trade.seller, trade.buyer, trade.sellerAmount),
            "Token transfer from seller to buyer failed"
        );

        // Transfer tokens from buyer to seller
        require(
            IERC20(trade.buyerToken).transferFrom(trade.buyer, trade.seller, trade.buyerAmount),
            "Token transfer from buyer to seller failed"
        );

        trade.isExecuted = true;

        emit TradeExecuted(_tradeId, trade.seller, trade.buyer);
    }

    /**
     * @dev Cancels a trade if it has not been executed and the caller is either the seller or buyer.
     * @param _tradeId The unique identifier of the trade.
     */
    function cancelTrade(bytes32 _tradeId) external nonReentrant {
        Trade storage trade = trades[_tradeId];
        require(!trade.isExecuted, "Trade already executed");
        require(msg.sender == trade.seller || msg.sender == trade.buyer, "Not authorized");

        delete trades[_tradeId];

        emit TradeCancelled(_tradeId, trade.seller, trade.buyer);
    }

    /**
     * @dev Reverses a trade if it has not been executed and the expiration time has passed.
     * @param _tradeId The unique identifier of the trade.
     */
    function reverseTrade(bytes32 _tradeId) external nonReentrant {
        Trade storage trade = trades[_tradeId];
        require(!trade.isExecuted, "Trade already executed");
        require(trade.expirationTime <= block.timestamp, "Trade has not expired yet");

        delete trades[_tradeId];

        emit TradeReversed(_tradeId, trade.seller, trade.buyer);
    }

    /**
     * @dev Pauses the contract, preventing new trades from being initiated.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing new trades to be initiated.
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
