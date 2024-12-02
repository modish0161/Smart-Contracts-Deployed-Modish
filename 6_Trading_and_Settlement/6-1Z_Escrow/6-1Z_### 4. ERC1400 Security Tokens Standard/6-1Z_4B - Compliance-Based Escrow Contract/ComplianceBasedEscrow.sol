// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

/**
 * @title ComplianceBasedEscrow
 * @dev Escrow contract for ERC1400 security tokens with KYC/AML compliance checks.
 */
contract ComplianceBasedEscrow is Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    IERC1400 public securityToken;

    struct Escrow {
        address seller;
        address buyer;
        uint256 amount;
        bool isComplete;
        bool isRefunded;
        string condition;
        bool conditionMet;
        bool compliancePassed;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => bool) public whitelistedInvestors;

    event EscrowCreated(uint256 indexed escrowId, address indexed seller, address indexed buyer, uint256 amount, string condition);
    event ComplianceChecked(uint256 indexed escrowId, bool passed);
    event ConditionUpdated(uint256 indexed escrowId, string condition, bool status);
    event TokensReleased(uint256 indexed escrowId, address indexed buyer);
    event TokensRefunded(uint256 indexed escrowId, address indexed seller);
    event InvestorWhitelisted(address indexed investor, bool status);

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

    constructor(address _securityToken) {
        require(_securityToken != address(0), "Invalid security token address");
        securityToken = IERC1400(_securityToken);
    }

    /**
     * @dev Adds or removes an investor from the whitelist.
     * @param investor The address of the investor.
     * @param status The whitelist status of the investor.
     */
    function whitelistInvestor(address investor, bool status) external onlyOwner {
        whitelistedInvestors[investor] = status;
        emit InvestorWhitelisted(investor, status);
    }

    /**
     * @dev Creates a new escrow for security tokens.
     * @param buyer Address of the buyer.
     * @param amount The amount of tokens to be held in escrow.
     * @param condition The condition that needs to be met for releasing the tokens.
     */
    function createEscrow(
        address buyer,
        uint256 amount,
        string calldata condition
    ) external whenNotPaused nonReentrant {
        require(whitelistedInvestors[buyer], "Buyer is not whitelisted");
        require(securityToken.isOperatorFor(msg.sender, msg.sender), "Seller is not an authorized operator");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            seller: msg.sender,
            buyer: buyer,
            amount: amount,
            isComplete: false,
            isRefunded: false,
            condition: condition,
            conditionMet: false,
            compliancePassed: false
        });

        // Transfer tokens to the contract
        securityToken.operatorTransferByPartition(bytes32(0), msg.sender, address(this), amount, "", "");

        emit EscrowCreated(escrowId, msg.sender, buyer, amount, condition);
    }

    /**
     * @dev Checks the compliance of the escrow condition.
     * @param escrowId The ID of the escrow.
     * @param passed The compliance status.
     */
    function checkCompliance(uint256 escrowId, bool passed) external onlyOwner escrowNotComplete(escrowId) {
        escrows[escrowId].compliancePassed = passed;
        emit ComplianceChecked(escrowId, passed);

        if (passed && escrows[escrowId].conditionMet) {
            releaseFunds(escrowId);
        }
    }

    /**
     * @dev Updates the status of the escrow condition.
     * @param escrowId The ID of the escrow.
     * @param status The status of the condition.
     */
    function updateCondition(uint256 escrowId, bool status) external onlyOwner escrowNotComplete(escrowId) {
        escrows[escrowId].conditionMet = status;
        emit ConditionUpdated(escrowId, escrows[escrowId].condition, status);

        if (status && escrows[escrowId].compliancePassed) {
            releaseFunds(escrowId);
        }
    }

    /**
     * @dev Releases the escrowed tokens to the buyer.
     * @param escrowId The ID of the escrow.
     */
    function releaseFunds(uint256 escrowId) internal escrowNotComplete(escrowId) {
        require(escrows[escrowId].conditionMet, "Condition not met");
        require(escrows[escrowId].compliancePassed, "Compliance not passed");

        Escrow storage escrow = escrows[escrowId];
        escrow.isComplete = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), escrow.buyer, escrow.amount, "", "");

        emit TokensReleased(escrowId, escrow.buyer);
    }

    /**
     * @dev Refunds the escrowed tokens back to the seller.
     * @param escrowId The ID of the escrow.
     */
    function refundFunds(uint256 escrowId) external onlySeller(escrowId) escrowNotComplete(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        escrow.isRefunded = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), escrow.seller, escrow.amount, "", "");

        emit TokensRefunded(escrowId, escrow.seller);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
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
            uint256 amount,
            bool isComplete,
            bool isRefunded,
            string memory condition,
            bool conditionMet,
            bool compliancePassed
        )
    {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.seller,
            escrow.buyer,
            escrow.amount,
            escrow.isComplete,
            escrow.isRefunded,
            escrow.condition,
            escrow.conditionMet,
            escrow.compliancePassed
        );
    }
}
