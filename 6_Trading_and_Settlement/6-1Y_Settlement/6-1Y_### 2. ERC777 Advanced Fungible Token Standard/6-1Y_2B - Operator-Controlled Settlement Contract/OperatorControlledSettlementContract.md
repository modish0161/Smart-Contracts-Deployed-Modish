### Contract Name: `OperatorControlledSettlementContract.sol`

Here’s a complete implementation of the **6-1Y_2B - Operator-Controlled Settlement Contract** using the ERC777 standard:

```solidity
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
```

### Key Features of the Contract:

1. **Operator-Based Settlement**:
   - The contract allows designated operators to manage the settlement process, ensuring trades are settled according to predefined conditions.

2. **Trade Initiation and Management**:
   - The `initiateTrade` function allows participants to set up a trade with the details like counterparty, token, and amount.
   - Trades are stored in a mapping with a unique `tradeId` for tracking.

3. **Trade Settlement**:
   - The `settleTrade` function allows operators to execute a trade, transferring the specified amount of tokens from the initiator to the counterparty.

4. **Trade Cancellation**:
   - The `cancelTrade` function allows the initiator or an operator to cancel a trade before it is settled.

5. **ERC777 Integration**:
   - The contract implements both `IERC777Recipient` and `IERC777Sender` interfaces, allowing it to handle incoming and outgoing ERC777 tokens.

6. **Pausable**:
   - The contract can be paused and unpaused by the owner, preventing trade settlements when paused.

7. **Compliance and Security**:
   - The contract uses OpenZeppelin’s `Ownable`, `ReentrancyGuard`, and `Pausable` modules for enhanced security and flexibility.

8. **Fallback Protection**:
   - The `receive()` function prevents accidental Ether transfers to the contract.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/OperatorControlledSettlementContract.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const OperatorControlledSettlementContract = await ethers.getContractFactory("OperatorControlledSettlementContract");
     const operatorControlledSettlementContract = await OperatorControlledSettlementContract.deploy();

     console.log("OperatorControlledSettlementContract deployed to:", operatorControlledSettlementContract.address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

4. **Deploy the Contract**:
   Deploy the contract to the desired network:
   ```bash
   npx hardhat run scripts/deploy.js --network <network-name>
   ```

5. **Testing**:
   Write unit tests in `test/OperatorControlledSettlementContract.test.js` using Mocha/Chai framework to ensure all

 functionalities work as expected.

6. **API Documentation**:
   Create a detailed API documentation using tools like Docusaurus or similar to document all functions, events, and modifiers for developers.

7. **User Guide**:
   Provide a user guide detailing how to use the contract for initiating trade settlements, adding/removing operators, and pausing/unpausing the contract.

8. **Upgradability**:
   Consider using OpenZeppelin’s `TransparentUpgradeableProxy` or `UUPSUpgradeable` if the contract needs to support upgradability in the future.

Let me know if you need further customizations or additional features!