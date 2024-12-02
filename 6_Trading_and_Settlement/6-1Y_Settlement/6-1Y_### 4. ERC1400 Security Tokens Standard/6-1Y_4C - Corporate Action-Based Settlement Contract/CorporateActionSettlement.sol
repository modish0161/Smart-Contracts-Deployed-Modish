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
    function isOperator(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function canTransfer(address to, uint256 value, bytes calldata data) external view returns (bool, bytes32);
}

contract CorporateActionSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1400 public securityToken;

    event CorporateActionExecuted(
        string indexed actionType,
        address indexed initiator,
        uint256 totalValue,
        bytes32 actionId
    );

    event TradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 value,
        bytes32 actionId,
        bool success
    );

    event ComplianceChecked(address indexed investor, bool status);

    struct CorporateAction {
        string actionType;
        address initiator;
        uint256 totalValue;
        bool isExecuted;
    }

    struct Trade {
        address seller;
        address buyer;
        uint256 value;
        bool isActive;
        bool isSettled;
    }

    mapping(bytes32 => CorporateAction) public corporateActions;
    mapping(bytes32 => Trade[]) public actionTrades;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public compliantInvestors;

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
     * @dev Marks an address as compliant.
     * @param investor The investor address to mark as compliant.
     */
    function addCompliance(address investor) external onlyOwner {
        compliantInvestors[investor] = true;
        emit ComplianceChecked(investor, true);
    }

    /**
     * @dev Removes compliance status from an investor.
     * @param investor The investor address to remove compliance status.
     */
    function removeCompliance(address investor) external onlyOwner {
        compliantInvestors[investor] = false;
        emit ComplianceChecked(investor, false);
    }

    /**
     * @dev Initiates a corporate action.
     * @param actionType The type of corporate action (e.g., "M&A", "Split", "Divestiture").
     * @param totalValue Total value of the corporate action.
     * @param actionId Unique identifier for the corporate action.
     */
    function initiateCorporateAction(
        string calldata actionType,
        uint256 totalValue,
        bytes32 actionId
    ) external onlyWhitelisted whenNotPaused nonReentrant {
        require(totalValue > 0, "Total value must be greater than 0");
        require(corporateActions[actionId].initiator == address(0), "Action ID already exists");

        corporateActions[actionId] = CorporateAction({
            actionType: actionType,
            initiator: msg.sender,
            totalValue: totalValue,
            isExecuted: false
        });

        emit CorporateActionExecuted(actionType, msg.sender, totalValue, actionId);
    }

    /**
     * @dev Creates a trade related to a corporate action.
     * @param actionId Unique identifier for the corporate action.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param value Amount of security tokens to be traded.
     */
    function createTrade(
        bytes32 actionId,
        address seller,
        address buyer,
        uint256 value
    ) external onlyWhitelisted whenNotPaused nonReentrant {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(corporateActions[actionId].initiator != address(0), "Action ID does not exist");
        require(!corporateActions[actionId].isExecuted, "Corporate action already executed");
        require(compliantInvestors[seller] && compliantInvestors[buyer], "Compliance not met for seller or buyer");
        require(securityToken.isOperator(address(this), seller), "Contract not approved to transfer seller's tokens");

        actionTrades[actionId].push(Trade({
            seller: seller,
            buyer: buyer,
            value: value,
            isActive: true,
            isSettled: false
        }));
    }

    /**
     * @dev Settles all trades related to a corporate action.
     * @param actionId Unique identifier for the corporate action.
     */
    function executeCorporateAction(bytes32 actionId) external onlyOwner whenNotPaused nonReentrant {
        require(corporateActions[actionId].initiator != address(0), "Action ID does not exist");
        require(!corporateActions[actionId].isExecuted, "Corporate action already executed");

        Trade[] storage trades = actionTrades[actionId];
        for (uint256 i = 0; i < trades.length; i++) {
            Trade storage trade = trades[i];
            if (trade.isActive && !trade.isSettled) {
                (bool canTransfer, ) = securityToken.canTransfer(trade.buyer, trade.value, "");
                if (canTransfer) {
                    securityToken.transferWithData(trade.buyer, trade.value, "");
                    trade.isSettled = true;
                    trade.isActive = false;
                    emit TradeSettled(trade.seller, trade.buyer, trade.value, actionId, true);
                } else {
                    emit TradeSettled(trade.seller, trade.buyer, trade.value, actionId, false);
                }
            }
        }

        corporateActions[actionId].isExecuted = true;
    }

    /**
     * @dev Pauses the contract, preventing any corporate actions or trades.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing corporate actions and trades.
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
