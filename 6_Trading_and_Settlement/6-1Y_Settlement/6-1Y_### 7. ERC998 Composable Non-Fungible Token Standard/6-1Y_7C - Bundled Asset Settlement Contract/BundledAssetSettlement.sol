// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BundledAssetSettlement is ERC998TopDown, Ownable, ReentrancyGuard, Pausable {
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

    event AssetBundled(
        uint256 indexed parentTokenId,
        address indexed childTokenAddress,
        uint256 indexed childTokenId
    );

    event AssetUnbundled(
        uint256 indexed parentTokenId,
        address indexed childTokenAddress,
        uint256 indexed childTokenId
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
     * @dev Executes the trade by transferring the parent token and all its bundled assets from the seller to the buyer.
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

        // Transfer the parent token and all bundled assets from seller to buyer
        safeTransferFrom(trade.seller, trade.buyer, trade.parentTokenId);

        trade.isSettled = true;

        emit TradeExecuted(tradeId, trade.seller, trade.buyer, trade.parentTokenId, trade.price);
    }

    /**
     * @dev Bundles an asset (child token) into the parent composable token.
     * @param parentTokenId The ID of the parent composable token.
     * @param childTokenAddress The address of the child token contract.
     * @param childTokenId The ID of the child token.
     */
    function bundleAsset(
        uint256 parentTokenId,
        address childTokenAddress,
        uint256 childTokenId
    ) external nonReentrant whenNotPaused {
        require(ownerOf(parentTokenId) == msg.sender, "Caller is not the owner of parent token");
        require(IERC721(childTokenAddress).ownerOf(childTokenId) == msg.sender, "Caller is not the owner of child token");

        // Transfer child token to the contract
        IERC721(childTokenAddress).safeTransferFrom(msg.sender, address(this), childTokenId);

        // Bundle the child token into the parent token
        _safeTransferChild(parentTokenId, msg.sender, childTokenAddress, childTokenId);

        emit AssetBundled(parentTokenId, childTokenAddress, childTokenId);
    }

    /**
     * @dev Unbundles an asset (child token) from the parent composable token.
     * @param parentTokenId The ID of the parent composable token.
     * @param childTokenAddress The address of the child token contract.
     * @param childTokenId The ID of the child token.
     */
    function unbundleAsset(
        uint256 parentTokenId,
        address childTokenAddress,
        uint256 childTokenId
    ) external nonReentrant whenNotPaused {
        require(ownerOf(parentTokenId) == msg.sender, "Caller is not the owner of parent token");

        // Unbundle the child token from the parent token
        _safeTransferChild(parentTokenId, address(this), childTokenAddress, childTokenId);

        // Transfer the child token back to the owner
        IERC721(childTokenAddress).safeTransferFrom(address(this), msg.sender, childTokenId);

        emit AssetUnbundled(parentTokenId, childTokenAddress, childTokenId);
    }

    /**
     * @dev Pauses the contract, preventing trade creation and execution, as well as bundling and unbundling of assets.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade creation and execution, as well as bundling and unbundling of assets.
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
