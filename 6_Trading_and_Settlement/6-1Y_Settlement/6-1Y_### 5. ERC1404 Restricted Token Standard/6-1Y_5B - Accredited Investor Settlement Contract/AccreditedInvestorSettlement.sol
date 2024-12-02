// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IERC1404 is IERC20 {
    function detectTransferRestriction(address from, address to, uint256 value) external view returns (uint8);
    function messageForTransferRestriction(uint8 restrictionCode) external view returns (string memory);
    function canTransfer(address to, uint256 value) external view returns (bool);
}

contract AccreditedInvestorSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1404 public restrictedToken;

    event TradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        bytes32 tradeId,
        bool success
    );

    event InvestorAccredited(address indexed investor, bool status);

    struct Trade {
        address seller;
        address buyer;
        uint256 value;
        bool isSettled;
    }

    mapping(bytes32 => Trade) public trades;
    mapping(address => bool) public accreditedInvestors;

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Caller is not accredited");
        _;
    }

    constructor(address _restrictedToken) {
        require(_restrictedToken != address(0), "Invalid token address");
        restrictedToken = IERC1404(_restrictedToken);
    }

    /**
     * @dev Accredits an investor.
     * @param investor The address to accredit.
     */
    function accreditInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
        emit InvestorAccredited(investor, true);
    }

    /**
     * @dev Revokes accreditation of an investor.
     * @param investor The address to revoke.
     */
    function revokeAccreditation(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
        emit InvestorAccredited(investor, false);
    }

    /**
     * @dev Creates a trade between a seller and a buyer.
     * @param tradeId Unique identifier for the trade.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param value Amount of tokens to be traded.
     */
    function createTrade(
        bytes32 tradeId,
        address seller,
        address buyer,
        uint256 value
    ) external onlyAccredited whenNotPaused nonReentrant {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");
        require(accreditedInvestors[seller] && accreditedInvestors[buyer], "Participants are not accredited");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            value: value,
            isSettled: false
        });
    }

    /**
     * @dev Settles a trade if compliance requirements are met.
     * @param tradeId Unique identifier for the trade.
     */
    function settleTrade(bytes32 tradeId) external onlyOwner whenNotPaused nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.seller != address(0) && trade.buyer != address(0), "Trade ID does not exist");
        require(!trade.isSettled, "Trade already settled");

        uint8 restrictionCode = restrictedToken.detectTransferRestriction(trade.seller, trade.buyer, trade.value);
        if (restrictionCode == 0) {
            restrictedToken.transferFrom(trade.seller, trade.buyer, trade.value);
            trade.isSettled = true;
            emit TradeSettled(trade.seller, trade.buyer, trade.value, tradeId, true);
        } else {
            emit TradeSettled(trade.seller, trade.buyer, trade.value, tradeId, false);
        }
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
