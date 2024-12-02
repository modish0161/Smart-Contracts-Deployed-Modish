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

contract AdvancedSettlementContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    // ERC777 interface identifiers
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    // Operators mapping
    mapping(address => bool) public operators;

    // Events
    event TradeSettled(address indexed seller, address indexed buyer, address token, uint256 amount);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

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
     * @dev Settles a trade between two parties.
     * @param token Address of the ERC777 token to be settled.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param amount Amount of tokens to be transferred from seller to buyer.
     */
    function settleTrade(address token, address seller, address buyer, uint256 amount) external nonReentrant whenNotPaused {
        require(operators[msg.sender], "Caller is not an operator");
        require(seller != address(0) && buyer != address(0), "Invalid addresses");
        require(amount > 0, "Amount must be greater than zero");

        // Transfer tokens from seller to buyer
        IERC777(token).operatorSend(seller, buyer, amount, "", "");

        emit TradeSettled(seller, buyer, token, amount);
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
