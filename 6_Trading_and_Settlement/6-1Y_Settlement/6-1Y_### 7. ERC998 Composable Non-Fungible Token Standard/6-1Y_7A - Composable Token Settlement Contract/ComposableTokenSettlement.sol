// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract ComposableTokenSettlement is Ownable, ReentrancyGuard, Pausable, ERC998TopDown {
    using SafeMath for uint256;

    struct Settlement {
        address buyer;
        address seller;
        uint256 parentTokenId;
        uint256 price;
        bool isSettled;
    }

    mapping(bytes32 => Settlement) public settlements;

    event SettlementCreated(
        bytes32 indexed settlementId,
        address indexed buyer,
        address indexed seller,
        uint256 parentTokenId,
        uint256 price
    );

    event SettlementExecuted(
        bytes32 indexed settlementId,
        address indexed buyer,
        address indexed seller,
        uint256 parentTokenId,
        uint256 price
    );

    modifier onlyValidAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC998TopDown(_name, _symbol) {}

    /**
     * @dev Creates a new settlement agreement.
     * @param settlementId The unique identifier for the settlement.
     * @param buyer The address of the buyer.
     * @param seller The address of the seller.
     * @param parentTokenId The ID of the composable parent token being exchanged.
     * @param price The price in wei for the settlement.
     */
    function createSettlement(
        bytes32 settlementId,
        address buyer,
        address seller,
        uint256 parentTokenId,
        uint256 price
    ) external onlyOwner whenNotPaused onlyValidAddress(buyer) onlyValidAddress(seller) {
        require(settlements[settlementId].buyer == address(0), "Settlement already exists");

        settlements[settlementId] = Settlement({
            buyer: buyer,
            seller: seller,
            parentTokenId: parentTokenId,
            price: price,
            isSettled: false
        });

        emit SettlementCreated(settlementId, buyer, seller, parentTokenId, price);
    }

    /**
     * @dev Executes the settlement by transferring the parent token and child tokens.
     * @param settlementId The unique identifier for the settlement.
     */
    function executeSettlement(bytes32 settlementId) external nonReentrant whenNotPaused {
        Settlement storage settlement = settlements[settlementId];
        require(settlement.buyer != address(0), "Settlement does not exist");
        require(!settlement.isSettled, "Settlement already executed");

        // Transfer the price from buyer to seller
        IERC20 paymentToken = IERC20(owner()); // Assuming the owner is the ERC20 token used for payment
        require(paymentToken.transferFrom(settlement.buyer, settlement.seller, settlement.price), "Payment failed");

        // Transfer the parent token from seller to buyer
        safeTransferFrom(settlement.seller, settlement.buyer, settlement.parentTokenId);

        settlement.isSettled = true;

        emit SettlementExecuted(settlementId, settlement.buyer, settlement.seller, settlement.parentTokenId, settlement.price);
    }

    /**
     * @dev Pauses the contract, preventing settlement creation and execution.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing settlement creation and execution.
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
