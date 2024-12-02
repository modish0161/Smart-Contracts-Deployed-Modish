### Contract Name: `AdvancedAtomicSwap.sol`

Here’s the complete implementation for the **6-1X_2A - Advanced Atomic Swap Contract** based on your specifications.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract AdvancedAtomicSwap is Ownable, ReentrancyGuard, IERC777Recipient {
    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct Swap {
        address initiator;
        address participant;
        address initiatorToken;
        address participantToken;
        uint256 initiatorAmount;
        uint256 participantAmount;
        bytes32 secretHash;
        bytes32 secret;
        address operator;
        uint256 startTime;
        uint256 timeLockDuration;
        bool isInitiated;
        bool isCompleted;
        bool isRefunded;
    }

    mapping(bytes32 => Swap) public swaps;

    event SwapInitiated(
        bytes32 indexed swapId,
        address indexed initiator,
        address indexed participant,
        address initiatorToken,
        address participantToken,
        uint256 initiatorAmount,
        uint256 participantAmount,
        bytes32 secretHash,
        uint256 startTime,
        uint256 timeLockDuration,
        address operator
    );

    event SwapCompleted(
        bytes32 indexed swapId,
        address indexed participant,
        bytes32 secret,
        address operator
    );

    event SwapRefunded(
        bytes32 indexed swapId,
        address indexed initiator,
        address operator
    );

    constructor() {
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev Initiates a new advanced atomic swap with an operator.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC777 token.
     * @param _participantToken The address of the participant's ERC777 token.
     * @param _initiatorAmount The amount of the initiator's token to be swapped.
     * @param _participantAmount The amount of the participant's token to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     * @param _operator The address of the authorized operator.
     */
    function initiateSwap(
        address _participant,
        address _initiatorToken,
        address _participantToken,
        uint256 _initiatorAmount,
        uint256 _participantAmount,
        bytes32 _secretHash,
        uint256 _timeLockDuration,
        address _operator
    ) external nonReentrant {
        require(_participant != address(0), "Invalid participant address");
        require(_initiatorToken != address(0), "Invalid initiator token address");
        require(_participantToken != address(0), "Invalid participant token address");
        require(_initiatorAmount > 0, "Initiator amount must be greater than 0");
        require(_participantAmount > 0, "Participant amount must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");
        require(_operator != address(0), "Invalid operator address");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorToken: _initiatorToken,
            participantToken: _participantToken,
            initiatorAmount: _initiatorAmount,
            participantAmount: _participantAmount,
            secretHash: _secretHash,
            secret: bytes32(0),
            operator: _operator,
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        IERC777(_initiatorToken).send(address(this), _initiatorAmount, "");

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorToken,
            _participantToken,
            _initiatorAmount,
            _participantAmount,
            _secretHash,
            block.timestamp,
            _timeLockDuration,
            _operator
        );
    }

    /**
     * @dev Completes the atomic swap by revealing the secret and verifying conditions.
     * @param _swapId The ID of the swap.
     * @param _secret The secret used to complete the swap.
     */
    function completeSwap(bytes32 _swapId, bytes32 _secret) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            msg.sender == swap.participant || msg.sender == swap.operator,
            "Only participant or operator can complete the swap"
        );
        require(
            keccak256(abi.encodePacked(_secret)) == swap.secretHash,
            "Invalid secret"
        );

        swap.secret = _secret;
        swap.isCompleted = true;

        IERC777(swap.participantToken).sendFrom(
            swap.participant,
            swap.initiator,
            swap.participantAmount,
            ""
        );
        IERC777(swap.initiatorToken).send(swap.participant, swap.initiatorAmount, "");

        emit SwapCompleted(_swapId, msg.sender, _secret, swap.operator);
    }

    /**
     * @dev Refunds the swap to the initiator if the time lock has expired and the swap is not completed.
     * @param _swapId The ID of the swap.
     */
    function refundSwap(bytes32 _swapId) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            msg.sender == swap.initiator || msg.sender == swap.operator,
            "Only initiator or operator can refund the swap"
        );
        require(
            block.timestamp >= swap.startTime.add(swap.timeLockDuration),
            "Time lock not expired"
        );

        swap.isRefunded = true;

        IERC777(swap.initiatorToken).send(swap.initiator, swap.initiatorAmount, "");

        emit SwapRefunded(_swapId, swap.initiator, swap.operator);
    }

    /**
     * @dev Called by the ERC777 token contract when tokens are sent to this contract.
     * @param from The address of the sender.
     * @param to The address of the recipient (this contract).
     * @param amount The amount of tokens sent.
     * @param userData The user-defined data.
     * @param operatorData The operator-defined data.
     */
    function tokensReceived(
        address /* operator */,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata /* operatorData */
    ) external override {
        // Optionally implement business logic based on received tokens
    }
}
```

### Deployment Steps Using Hardhat

1. **Prerequisites**:
   - Install Hardhat and OpenZeppelin dependencies:
     ```bash
     npm install --save-dev hardhat @openzeppelin/contracts
     ```
   - Create a Hardhat project if you haven't already:
     ```bash
     npx hardhat
     ```

2. **Contract Compilation**:
   - Save the contract code in `contracts/AdvancedAtomicSwap.sol`.
   - Compile the contract:
     ```bash
     npx hardhat compile
     ```

3. **Deployment Script**:
   - Create a deployment script in the `scripts` folder, e.g., `scripts/deploy.js`:
     ```javascript
     const hre = require("hardhat");

     async function main() {
       const [deployer] = await hre.ethers.getSigners();
       console.log("Deploying contracts with the account:", deployer.address);

       const AdvancedAtomicSwap = await hre.ethers.getContractFactory("AdvancedAtomicSwap");
       const advancedAtomicSwap = await AdvancedAtomicSwap.deploy();

       await advancedAtomicSwap.deployed();

       console.log("AdvancedAtomicSwap deployed to:", advancedAtomicSwap.address);
     }

     main().catch((error) => {
       console.error(error);
       process.exitCode = 1;
     });
     ```
   - Deploy the contract:
     ```bash
     npx hardhat run scripts/deploy.js --network <network-name>
     ```
   Replace `<network-name>` with the desired network (e.g., `localhost`, `rinkeby`, `mainnet`).

4. **Test Suite**:
   - Create a test file in the `test` folder, e.g., `test/AdvancedAtomicSwap.test.js`:
     ```javascript


     const { expect } = require("chai");
     const { ethers } = require("hardhat");

     describe("AdvancedAtomicSwap", function () {
       let swapContract;
       let initiator;
       let participant;
       let operator;
       let initiatorToken;
       let participantToken;

       beforeEach(async function () {
         [initiator, participant, operator] = await ethers.getSigners();

         const ERC777Mock = await ethers.getContractFactory("ERC777Mock");
         initiatorToken = await ERC777Mock.deploy("Initiator Token", "INIT", [], []);
         participantToken = await ERC777Mock.deploy("Participant Token", "PART", [], []);

         const AdvancedAtomicSwap = await ethers.getContractFactory("AdvancedAtomicSwap");
         swapContract = await AdvancedAtomicSwap.deploy();
         await swapContract.deployed();
       });

       it("Should initiate an advanced swap with operator", async function () {
         const secretHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("secret"));
         const timeLockDuration = 3600; // 1 hour

         await initiatorToken.send(swapContract.address, 100, "");

         await swapContract.initiateSwap(
           participant.address,
           initiatorToken.address,
           participantToken.address,
           100,
           50,
           secretHash,
           timeLockDuration,
           operator.address
         );

         const swapId = await swapContract.swaps(ethers.utils.keccak256(
           ethers.utils.defaultAbiCoder.encode(
             ["address", "address", "bytes32"],
             [initiator.address, participant.address, secretHash]
           )
         ));

         expect(swapId.isInitiated).to.be.true;
       });

       // Add more test cases to cover completeSwap and refundSwap functions
     });
     ```
   - Run the tests:
     ```bash
     npx hardhat test
     ```

5. **Additional Customization**:
   - You can extend the contract to include features like multi-signature approvals, oracle price feeds, etc., based on your requirements.

6. **Documentation**:
   - Generate API documentation and provide detailed descriptions of each function, event, and parameter within the contract.

This setup allows for advanced atomic swaps using ERC777 tokens, leveraging operator permissions for additional control and security. If you need any additional features or customizations, feel free to ask!