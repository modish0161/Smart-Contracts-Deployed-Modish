// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC1400 is IERC20 {
    function issue(address to, uint256 value, bytes calldata data) external;
    function redeem(uint256 value, bytes calldata data) external;
    function transferWithData(address to, uint256 value, bytes calldata data) external;
    function getDocument(bytes32 name) external view returns (string memory, bytes32);
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external;
    function isOperator(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
}

contract SecurityTokenSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1400 public securityToken;

    event TradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        bytes32 tradeId,
        bool success
    );

    event TradeCreated(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        bytes32 tradeId
    );

    event TradeCanceled(bytes32 indexed tradeId);

    struct Trade {
        address seller;
        address buyer;
        uint256 value;
        bool isActive;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public kycedInvestors;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Caller is not whitelisted");
        _;
    }

    constructor(address _securityToken) {
        require(_securityToken != address(0), "Invalid token address");
        securityToken = IERC1400(_securityToken);
    }

    /**
     * @dev Adds an address to the whitelist.
     * @param account The address to whitelist.
     */
    function addToWhitelist(address account) external onlyOwner {
        whitelist[account] = true;
    }

    /**
     * @dev Removes an address from the whitelist.
     * @param account The address to remove from the whitelist.
     */
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /**
     * @dev Marks an address as KYCed.
     * @param investor The investor address to mark as KYCed.
     */
    function addKYC(address investor) external onlyOwner {
        kycedInvestors[investor] = true;
    }

    /**
     * @dev Removes KYC status from an investor.
     * @param investor The investor address to remove KYC status.
     */
    function removeKYC(address investor) external onlyOwner {
        kycedInvestors[investor] = false;
    }

    /**
     * @dev Creates a trade between seller and buyer.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param value Amount of security tokens to be traded.
     * @param tradeId Unique identifier for the trade.
     */
    function createTrade(
        address seller,
        address buyer,
        uint256 value,
        bytes32 tradeId
    ) external onlyWhitelisted whenNotPaused nonReentrant {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");
        require(kycedInvestors[seller] && kycedInvestors[buyer], "KYC not completed for seller or buyer");
        require(securityToken.isOperator(address(this), seller), "Contract not approved to transfer seller's tokens");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            value: value,
            isActive: true,
            isSettled: false
        });

        emit TradeCreated(seller, buyer, value, tradeId);
    }

    /**
     * @dev Settles a trade by transferring security tokens from seller to buyer.
     * @param tradeId Unique identifier for the trade.
     */
    function settleTrade(bytes32 tradeId) external whenNotPaused nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.buyer == msg.sender, "Only the buyer can settle the trade");
        require(kycedInvestors[trade.buyer], "Buyer is not KYCed");

        securityToken.transferWithData(trade.buyer, trade.value, "");

        trade.isActive = false;
        trade.isSettled = true;

        emit TradeSettled(trade.seller, trade.buyer, trade.value, tradeId, true);
    }

    /**
     * @dev Cancels an active trade.
     * @param tradeId Unique identifier for the trade.
     */
    function cancelTrade(bytes32 tradeId) external onlyOwner {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");

        trade.isActive = false;

        emit TradeCanceled(tradeId);
    }

    /**
     * @dev Pauses the contract, preventing any trades.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trades.
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
