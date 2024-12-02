// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract OperatorControlledSettlementContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // ERC777 interface identifiers
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    // Operators mapping
    mapping(address => bool) public operators;

    // Events
    event TradeInitiated(address indexed initiator, address indexed counterparty, address token, uint256 amount, bytes32 tradeId);
    event TradeSettled(address indexed initiator, address indexed counterparty, address token, uint256 amount, bytes32 tradeId);
    event TradeCancelled(address indexed initiator, address indexed counterparty, bytes32 tradeId);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    // Structure to hold trade details
    struct Trade {
        address initiator;
        address counterparty;
        address token;
        uint256 amount;
        bool isActive;
    }

    // Mapping to hold trades
    mapping(bytes32 => Trade) public trades;

    constructor() {
        // Register the contract as an ERC777 recipient and sender
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _erc1820.setInterfaceImplementer(address(this), TOKENS_SENDER_INTERFACE_HASH, address(this));
    }

    /**
     * @dev Adds an operator who can manage settlements on behalf of users.
     * @param _operator Address of the operator to be added.
     */
    function addOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Operator cannot be zero address");
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }

    /**
     * @dev Removes an operator.
     * @param _operator Address of the operator to be removed.
     */
    function removeOperator(address _operator) external onlyOwner {
        require(operators[_operator], "Operator does not exist");
        operators[_operator] = false;
        emit OperatorRemoved(_operator);
    }

    /**
     * @dev Initiates a trade between two parties.
     * @param counterparty Address of the counterparty involved in the trade.
     * @param token Address of the ERC777 token to be settled.
     * @param amount Amount of tokens to be transferred.
     * @param tradeId Unique identifier for the trade.
     */
    function initiateTrade(address counterparty, address token, uint256 amount, bytes32 tradeId) external whenNotPaused nonReentrant {
        require(counterparty != address(0), "Counterparty cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(trades[tradeId].initiator == address(0), "Trade ID already exists");

        // Create trade struct and store in mapping
        trades[tradeId] = Trade({
            initiator: msg.sender,
            counterparty: counterparty,
            token: token,
            amount: amount,
            isActive: true
        });

        emit TradeInitiated(msg.sender, counterparty, token, amount, tradeId);
    }

    /**
     * @dev Settles a trade between two parties.
     * @param tradeId Unique identifier for the trade to be settled.
     */
    function settleTrade(bytes32 tradeId) external nonReentrant whenNotPaused {
        require(operators[msg.sender], "Caller is not an operator");
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.initiator != address(0) && trade.counterparty != address(0), "Invalid trade participants");

        // Transfer tokens from initiator to counterparty
        IERC777(trade.token).operatorSend(trade.initiator, trade.counterparty, trade.amount, "", "");

        // Mark trade as settled
        trade.isActive = false;

        emit TradeSettled(trade.initiator, trade.counterparty, trade.token, trade.amount, tradeId);
    }

    /**
     * @dev Cancels an active trade.
     * @param tradeId Unique identifier for the trade to be cancelled.
     */
    function cancelTrade(bytes32 tradeId) external nonReentrant whenNotPaused {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.initiator == msg.sender || operators[msg.sender], "Caller is not authorized to cancel trade");

        // Mark trade as cancelled
        trade.isActive = false;

        emit TradeCancelled(trade.initiator, trade.counterparty, tradeId);
    }

    /**
     * @dev Pauses the contract, preventing any trade settlements.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing trade settlements.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to handle ERC777 tokens sent to the contract.
     * Required by the ERC777 standard.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called when tokens are sent to this contract.
        // Implement any necessary logic here, e.g., logging or processing the transfer.
    }

    /**
     * @dev Function to handle ERC777 tokens sent from the contract.
     * Required by the ERC777 standard.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called when tokens are sent from this contract.
        // Implement any necessary logic here, e.g., logging or processing the transfer.
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
