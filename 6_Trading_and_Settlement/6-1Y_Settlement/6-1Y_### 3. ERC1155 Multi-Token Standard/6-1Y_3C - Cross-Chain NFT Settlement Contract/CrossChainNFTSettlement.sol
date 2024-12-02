// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IBridge {
    function lockTokens(
        address tokenAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        bytes32 destinationChain
    ) external;

    function unlockTokens(
        address tokenAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        bytes32 sourceChain
    ) external;
}

contract CrossChainNFTSettlement is ERC1155, Ownable, ReentrancyGuard, Pausable, ERC1155Supply {
    event CrossChainTradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    );

    event CrossChainTradeCreated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    );

    event TradeCanceled(bytes32 indexed tradeId);

    struct Trade {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 amount;
        bytes32 destinationChain;
        bool isActive;
    }

    mapping(bytes32 => Trade) public trades;
    IBridge public bridge;

    constructor(string memory uri, address bridgeAddress) ERC1155(uri) {
        require(bridgeAddress != address(0), "Invalid bridge address");
        bridge = IBridge(bridgeAddress);
    }

    /**
     * @dev Creates a new cross-chain trade.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param tokenId ID of the NFT being traded.
     * @param amount Amount of the NFT being traded.
     * @param tradeId Unique identifier for the trade.
     * @param destinationChain Identifier of the destination chain.
     */
    function createCrossChainTrade(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    ) external whenNotPaused nonReentrant onlyOwner {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");
        require(isApprovedForAll(seller, address(this)), "Contract not approved to transfer seller's tokens");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            tokenId: tokenId,
            amount: amount,
            destinationChain: destinationChain,
            isActive: true
        });

        // Lock tokens on the current chain
        safeTransferFrom(seller, address(this), tokenId, amount, "");
        bridge.lockTokens(address(this), buyer, tokenId, amount, destinationChain);

        emit CrossChainTradeCreated(seller, buyer, tokenId, amount, tradeId, destinationChain);
    }

    /**
     * @dev Completes a cross-chain trade by unlocking tokens on the destination chain.
     * @param tradeId Unique identifier for the trade.
     */
    function settleCrossChainTrade(bytes32 tradeId) external whenNotPaused nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.buyer == msg.sender, "Only the buyer can settle the trade");

        // Unlock tokens on the destination chain
        bridge.unlockTokens(address(this), trade.buyer, trade.tokenId, trade.amount, trade.destinationChain);

        // Mark trade as inactive
        trade.isActive = false;

        emit CrossChainTradeSettled(trade.seller, trade.buyer, trade.tokenId, trade.amount, tradeId, trade.destinationChain);
    }

    /**
     * @dev Cancels an active cross-chain trade.
     * @param tradeId Unique identifier for the trade.
     */
    function cancelTrade(bytes32 tradeId) external onlyOwner {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");

        // Return tokens to the seller
        safeTransferFrom(address(this), trade.seller, trade.tokenId, trade.amount, "");

        // Mark trade as inactive
        trade.isActive = false;

        emit TradeCanceled(tradeId);
    }

    /**
     * @dev Pauses the contract, preventing any cross-chain trades.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing cross-chain trades.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Override required for ERC1155Supply.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
