// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract VaultTokenSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    ERC4626 public vaultToken;

    struct Trade {
        address buyer;
        address seller;
        uint256 amount;
        uint256 vaultShares;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;

    event TradeCreated(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 vaultShares
    );

    event TradeSettled(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 vaultShares
    );

    constructor(address _vaultToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        vaultToken = ERC4626(_vaultToken);
    }

    /**
     * @dev Creates a trade agreement between a buyer and a seller.
     * @param tradeId The unique identifier for the trade.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param amount The amount of tokens being traded.
     * @param vaultShares The number of vault shares being traded.
     */
    function createTrade(
        bytes32 tradeId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 vaultShares
    ) external onlyOwner whenNotPaused {
        require(buyer != address(0) && seller != address(0), "Invalid buyer or seller address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");

        trades[tradeId] = Trade({
            buyer: buyer,
            seller: seller,
            amount: amount,
            vaultShares: vaultShares,
            isSettled: false
        });

        emit TradeCreated(tradeId, seller, buyer, amount, vaultShares);
    }

    /**
     * @dev Settles a trade once both parties have agreed on the conditions.
     * @param tradeId The unique identifier for the trade.
     */
    function settleTrade(bytes32 tradeId) external nonReentrant whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.seller != address(0) && trade.buyer != address(0), "Trade ID does not exist");
        require(!trade.isSettled, "Trade already settled");

        // Transfer the amount of tokens from buyer to seller
        vaultToken.asset().safeTransferFrom(trade.buyer, trade.seller, trade.amount);

        // Transfer the vault shares from seller to buyer
        vaultToken.safeTransferFrom(trade.seller, trade.buyer, trade.vaultShares);

        trade.isSettled = true;

        emit TradeSettled(tradeId, trade.seller, trade.buyer, trade.amount, trade.vaultShares);
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
