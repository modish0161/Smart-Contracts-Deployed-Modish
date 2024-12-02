### Smart Contract: `ConditionalRealTimeEscrow.sol`

Below is the Solidity implementation for the **6-1Z_2C - Conditional Real-Time Escrow Contract** using the ERC777 standard. This contract monitors escrow conditions in real-time and releases the funds as soon as the conditions are satisfied.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ConditionalRealTimeEscrow
 * @dev Conditional Real-Time Escrow Contract using ERC777, supporting real-time monitoring of conditions for fund release.
 */
contract ConditionalRealTimeEscrow is IERC777Recipient, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    IERC777 public escrowToken;
    address public depositor;
    address public beneficiary;

    uint256 public escrowAmount;
    bool public fundsReleased;
    bool public fundsRefunded;

    string public escrowCondition; // The condition that needs to be met for releasing the funds
    mapping(string => bool) private conditionStatus;

    event FundsDeposited(address indexed from, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event FundsRefunded(address indexed to, uint256 amount);
    event ConditionUpdated(string condition, bool status);

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
        _;
    }

    modifier fundsNotReleasedOrRefunded() {
        require(!fundsReleased, "Funds already released");
        require(!fundsRefunded, "Funds already refunded");
        _;
    }

    constructor(
        address _escrowToken,
        address _depositor,
        address _beneficiary,
        uint256 _amount,
        string memory _escrowCondition
    ) {
        require(_escrowToken != address(0), "Invalid token address");
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(bytes(_escrowCondition).length > 0, "Condition cannot be empty");

        escrowToken = IERC777(_escrowToken);
        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowAmount = _amount;
        escrowCondition = _escrowCondition;
        conditionStatus[_escrowCondition] = false;

        // Register the contract as a recipient of ERC777 tokens
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    /**
     * @dev Deposits the ERC777 tokens into escrow.
     */
    function depositFunds() external onlyDepositor nonReentrant fundsNotReleasedOrRefunded {
        require(escrowToken.balanceOf(depositor) >= escrowAmount, "Insufficient token balance");
        escrowToken.operatorSend(depositor, address(this), escrowAmount, "", "");
        emit FundsDeposited(depositor, escrowAmount);
    }

    /**
     * @dev Updates the status of the escrow condition.
     * @param _condition The condition being updated.
     * @param _status The status of the condition.
     */
    function updateConditionStatus(string memory _condition, bool _status) external onlyOwner {
        require(bytes(_condition).length > 0, "Condition cannot be empty");
        require(keccak256(bytes(_condition)) == keccak256(bytes(escrowCondition)), "Condition mismatch");

        conditionStatus[_condition] = _status;
        emit ConditionUpdated(_condition, _status);

        if (_status) {
            releaseFunds();
        }
    }

    /**
     * @dev Releases the escrowed funds to the beneficiary when the condition is met.
     */
    function releaseFunds() internal nonReentrant fundsNotReleasedOrRefunded {
        require(conditionStatus[escrowCondition], "Condition not met");

        fundsReleased = true;
        escrowToken.send(beneficiary, escrowAmount, "");
        emit FundsReleased(beneficiary, escrowAmount);
    }

    /**
     * @dev Refunds the escrowed funds back to the depositor.
     */
    function refundFunds() external onlyDepositor nonReentrant fundsNotReleasedOrRefunded {
        fundsRefunded = true;
        escrowToken.send(depositor, escrowAmount, "");
        emit FundsRefunded(depositor, escrowAmount);
    }

    /**
     * @dev IERC777Recipient hook implementation, called when the contract receives ERC777 tokens.
     */
    function tokensReceived(
        address /*operator*/,
        address from,
        address to,
        uint256 amount,
        bytes calldata /*data*/,
        bytes calldata /*operatorData*/
    ) external override {
        require(msg.sender == address(escrowToken), "Tokens received not from escrowToken");
        require(to == address(this), "Tokens not sent to this contract");
        require(from == depositor, "Tokens not sent from depositor");
        require(amount == escrowAmount, "Incorrect escrow amount received");
    }

    /**
     * @dev Get the escrow details.
     */
    function getEscrowDetails()
        external
        view
        returns (
            address _depositor,
            address _beneficiary,
            uint256 _escrowAmount,
            bool _fundsReleased,
            bool _fundsRefunded,
            string memory _escrowCondition,
            bool _conditionStatus
        )
    {
        return (depositor, beneficiary, escrowAmount, fundsReleased, fundsRefunded, escrowCondition, conditionStatus[escrowCondition]);
    }
}
```

### Key Features of the Contract:

1. **ERC777 Integration**:
   - Utilizes ERC777 for escrow functionality, providing advanced token transfer features such as hooks and operator permissions.

2. **Real-Time Condition Monitoring**:
   - The contract allows real-time updates of the escrow condition. The funds are released automatically when the specified condition is met, making the process efficient and reducing transaction delays.

3. **Deposits and Withdrawals**:
   - `depositFunds()`: Allows the depositor to deposit ERC777 tokens into the escrow.
   - `updateConditionStatus()`: Allows the owner to update the condition status, triggering an automatic fund release if the condition is met.
   - `refundFunds()`: The depositor can refund the tokens back if the conditions are not met or if the escrow needs to be canceled.

4. **Security Features**:
   - Role-based access control ensures that only the depositor or owner can trigger fund actions.
   - The `tokensReceived` hook ensures only the depositor can send the exact amount of tokens to the contract.

5. **Event Logging**:
   - Logs events such as `FundsDeposited`, `FundsReleased`, `FundsRefunded`, and `ConditionUpdated` to track key actions in the contract.

6. **Emergency Fallbacks**:
   - The contract supports a refund mechanism, allowing a fallback option for the depositor to reclaim their tokens if necessary.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/ConditionalRealTimeEscrow.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const escrowTokenAddress = "0xYourERC777TokenAddress"; // Replace with actual ERC777 token address
     const depositorAddress = "0xDepositorAddress"; // Replace with depositor address
     const beneficiaryAddress = "0xBeneficiaryAddress"; // Replace with beneficiary address
     const amount = ethers.utils.parseUnits("1000", 18); // Example: 1000 tokens with 18 decimals
     const condition = "Escrow Condition Example"; // Replace with your escrow condition

     const ConditionalRealTimeEscrow = await ethers.getContractFactory("ConditionalRealTimeEscrow");
     const escrow = await ConditionalRealTimeEscrow.deploy(
       escrowTokenAddress,
       depositorAddress,
       beneficiaryAddress,
       amount,
       condition
     );

     console.log("ConditionalRealTimeEscrow deployed to:", escrow.address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

4. **Deploy**:
   Run the deployment script:
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetwork
   ```

### Additional Customization:

- **Oracle Integration**: Integrate with oracles like Chainlink to verify external conditions automatically.
- **Multi-Signature Approvals**: Add multi-signature requirements for condition updates or fund release, improving the security of the escrow operations.
- **Multi-Condition Escrow**: Implement support for multiple conditions that need to be met for releasing funds,

 enabling more sophisticated use cases.
