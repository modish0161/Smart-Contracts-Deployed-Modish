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
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YieldDrivenSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    ERC4626 public vaultToken;

    // Set of authorized participants who can trade yield-generating vault tokens
    EnumerableSet.AddressSet private authorizedParticipants;

    struct Trade {
        address buyer;
        address seller;
        uint256 amount;
        uint256 vaultShares;
        uint256 accruedYield;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;

    event TradeCreated(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 vaultShares,
        uint256 accruedYield
    );

    event TradeSettled(
        bytes32 indexed tradeId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 vaultShares,
        uint256 accruedYield
    );

    modifier onlyAuthorized() {
        require(isAuthorizedParticipant(msg.sender), "Not an authorized participant");
        _;
    }

    constructor(address _vaultToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        vaultToken = ERC4626(_vaultToken);
    }

    /**
     * @dev Adds an address to the set of authorized participants.
     * @param participant The address to be added.
     */
    function addAuthorizedParticipant(address participant) external onlyOwner {
        require(participant != address(0), "Invalid address");
        authorizedParticipants.add(participant);
    }

    /**
     * @dev Removes an address from the set of authorized participants.
     * @param participant The address to be removed.
     */
    function removeAuthorizedParticipant(address participant) external onlyOwner {
        authorizedParticipants.remove(participant);
    }

    /**
     * @dev Checks if an address is an authorized participant.
     * @param participant The address to check.
     */
    function isAuthorizedParticipant(address participant) public view returns (bool) {
        return authorizedParticipants.contains(participant);
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
    ) external onlyAuthorized whenNotPaused {
        require(buyer != address(0) && seller != address(0), "Invalid buyer or seller address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");

        uint256 accruedYield = calculateYield(vaultShares);

        trades[tradeId] = Trade({
            buyer: buyer,
            seller: seller,
            amount: amount,
            vaultShares: vaultShares,
            accruedYield: accruedYield,
            isSettled: false
        });

        emit TradeCreated(tradeId, seller, buyer, amount, vaultShares, accruedYield);
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

        // Transfer accrued yield from seller to buyer
        vaultToken.asset().safeTransferFrom(trade.seller, trade.buyer, trade.accruedYield);

        trade.isSettled = true;

        emit TradeSettled(tradeId, trade.seller, trade.buyer, trade.amount, trade.vaultShares, trade.accruedYield);
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

    /**
     * @dev Calculate yield based on the number of vault shares.
     * @param vaultShares The number of vault shares.
     * @return The calculated yield.
     */
    function calculateYield(uint256 vaultShares) internal view returns (uint256) {
        // Placeholder logic for calculating yield
        // Replace this with the actual logic based on vault's performance
        uint256 yieldRate = 5; // Example: 5% yield rate
        return vaultShares.mul(yieldRate).div(100);
    }
}
