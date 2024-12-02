// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title NFTEscrow
 * @dev An Escrow Contract for NFTs using the ERC1155 standard, supporting the locking of NFTs until conditions are met.
 */
contract NFTEscrow is IERC1155Receiver, Ownable, ReentrancyGuard {
    struct Escrow {
        address seller;
        address buyer;
        uint256[] tokenIds;
        uint256[] amounts;
        bool isComplete;
        bool isRefunded;
        string condition;
        bool conditionMet;
    }

    IERC1155 public tokenContract;
    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;

    event EscrowCreated(uint256 indexed escrowId, address indexed seller, address indexed buyer, uint256[] tokenIds, uint256[] amounts, string condition);
    event ConditionUpdated(uint256 indexed escrowId, string condition, bool status);
    event TokensReleased(uint256 indexed escrowId, address indexed buyer);
    event TokensRefunded(uint256 indexed escrowId, address indexed seller);

    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Caller is not the seller");
        _;
    }

    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Caller is not the buyer");
        _;
    }

    modifier escrowNotComplete(uint256 escrowId) {
        require(!escrows[escrowId].isComplete, "Escrow already completed");
        require(!escrows[escrowId].isRefunded, "Escrow already refunded");
        _;
    }

    constructor(address _tokenContract) {
        require(_tokenContract != address(0), "Invalid token contract address");
        tokenContract = IERC1155(_tokenContract);
    }

    /**
     * @dev Creates a new escrow for NFTs.
     * @param buyer Address of the buyer.
     * @param tokenIds Array of token IDs.
     * @param amounts Array of amounts corresponding to each token ID.
     * @param condition The condition that needs to be met for releasing the funds.
     */
    function createEscrow(
        address buyer,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        string calldata condition
    ) external nonReentrant {
        require(buyer != address(0), "Buyer address cannot be zero");
        require(tokenIds.length == amounts.length, "Token IDs and amounts length mismatch");
        require(bytes(condition).length > 0, "Condition cannot be empty");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            seller: msg.sender,
            buyer: buyer,
            tokenIds: tokenIds,
            amounts: amounts,
            isComplete: false,
            isRefunded: false,
            condition: condition,
            conditionMet: false
        });

        // Transfer tokens to the contract
        tokenContract.safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");

        emit EscrowCreated(escrowId, msg.sender, buyer, tokenIds, amounts, condition);
    }

    /**
     * @dev Updates the status of the escrow condition.
     * @param escrowId The ID of the escrow.
     * @param status The status of the condition.
     */
    function updateCondition(uint256 escrowId, bool status) external onlyOwner escrowNotComplete(escrowId) {
        escrows[escrowId].conditionMet = status;
        emit ConditionUpdated(escrowId, escrows[escrowId].condition, status);

        if (status) {
            releaseFunds(escrowId);
        }
    }

    /**
     * @dev Releases the escrowed tokens to the buyer.
     * @param escrowId The ID of the escrow.
     */
    function releaseFunds(uint256 escrowId) internal escrowNotComplete(escrowId) {
        require(escrows[escrowId].conditionMet, "Condition not met");

        Escrow storage escrow = escrows[escrowId];
        escrow.isComplete = true;
        tokenContract.safeBatchTransferFrom(address(this), escrow.buyer, escrow.tokenIds, escrow.amounts, "");

        emit TokensReleased(escrowId, escrow.buyer);
    }

    /**
     * @dev Refunds the escrowed tokens back to the seller.
     * @param escrowId The ID of the escrow.
     */
    function refundFunds(uint256 escrowId) external onlySeller(escrowId) escrowNotComplete(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        escrow.isRefunded = true;
        tokenContract.safeBatchTransferFrom(address(this), escrow.seller, escrow.tokenIds, escrow.amounts, "");

        emit TokensRefunded(escrowId, escrow.seller);
    }

    /**
     * @dev IERC1155Receiver hook implementation, required to receive ERC1155 tokens.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev IERC1155Receiver hook implementation, required to receive ERC1155 batch tokens.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Supports the interface required for ERC1155Receiver.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /**
     * @dev Gets the escrow details.
     * @param escrowId The ID of the escrow.
     */
    function getEscrowDetails(uint256 escrowId)
        external
        view
        returns (
            address seller,
            address buyer,
            uint256[] memory tokenIds,
            uint256[] memory amounts,
            bool isComplete,
            bool isRefunded,
            string memory condition,
            bool conditionMet
        )
    {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.seller,
            escrow.buyer,
            escrow.tokenIds,
            escrow.amounts,
            escrow.isComplete,
            escrow.isRefunded,
            escrow.condition,
            escrow.conditionMet
        );
    }
}
