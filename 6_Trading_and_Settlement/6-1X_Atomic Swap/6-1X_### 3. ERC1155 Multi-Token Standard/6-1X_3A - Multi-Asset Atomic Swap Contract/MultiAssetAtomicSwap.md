### Contract Name: `MultiAssetAtomicSwap.sol`

Here’s the complete implementation for the **6-1X_3A - Multi-Asset Atomic Swap Contract** based on your specifications.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiAssetAtomicSwap is AccessControl, ReentrancyGuard, Pausable, ERC1155Holder {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address[] initiatorTokens;
        address[] participantTokens;
        uint256[] initiatorIds;
        uint256[] participantIds;
        uint256[] initiatorAmounts;
        uint256[] participantAmounts;
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
        address[] initiatorTokens,
        address[] participantTokens,
        uint256[] initiatorIds,
        uint256[] participantIds,
        uint256[] initiatorAmounts,
        uint256[] participantAmounts,
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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Initiates a new multi-asset atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorTokens The addresses of the initiator's ERC1155 tokens.
     * @param _participantTokens The addresses of the participant's ERC1155 tokens.
     * @param _initiatorIds The token IDs of the initiator's tokens.
     * @param _participantIds The token IDs of the participant's tokens.
     * @param _initiatorAmounts The amounts of the initiator's tokens to be swapped.
     * @param _participantAmounts The amounts of the participant's tokens to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     * @param _operator The address of the authorized operator.
     */
    function initiateSwap(
        address _participant,
        address[] memory _initiatorTokens,
        address[] memory _participantTokens,
        uint256[] memory _initiatorIds,
        uint256[] memory _participantIds,
        uint256[] memory _initiatorAmounts,
        uint256[] memory _participantAmounts,
        bytes32 _secretHash,
        uint256 _timeLockDuration,
        address _operator
    ) external whenNotPaused nonReentrant {
        require(_participant != address(0), "Invalid participant address");
        require(_initiatorTokens.length > 0, "No initiator tokens provided");
        require(_participantTokens.length > 0, "No participant tokens provided");
        require(_initiatorTokens.length == _initiatorIds.length, "Mismatched initiator tokens and IDs");
        require(_participantTokens.length == _participantIds.length, "Mismatched participant tokens and IDs");
        require(_initiatorTokens.length == _initiatorAmounts.length, "Mismatched initiator tokens and amounts");
        require(_participantTokens.length == _participantAmounts.length, "Mismatched participant tokens and amounts");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");
        require(_operator != address(0), "Invalid operator address");
        require(hasRole(OPERATOR_ROLE, _operator), "Operator is not authorized");

        bytes32 swapId = keccak256(
            abi.encodePacked(msg.sender, _participant, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            initiator: msg.sender,
            participant: _participant,
            initiatorTokens: _initiatorTokens,
            participantTokens: _participantTokens,
            initiatorIds: _initiatorIds,
            participantIds: _participantIds,
            initiatorAmounts: _initiatorAmounts,
            participantAmounts: _participantAmounts,
            secretHash: _secretHash,
            secret: bytes32(0),
            operator: _operator,
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        for (uint256 i = 0; i < _initiatorTokens.length; i++) {
            IERC1155(_initiatorTokens[i]).safeTransferFrom(msg.sender, address(this), _initiatorIds[i], _initiatorAmounts[i], "");
        }

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorTokens,
            _participantTokens,
            _initiatorIds,
            _participantIds,
            _initiatorAmounts,
            _participantAmounts,
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

        for (uint256 i = 0; i < swap.participantTokens.length; i++) {
            IERC1155(swap.participantTokens[i]).safeTransferFrom(
                swap.participant,
                swap.initiator,
                swap.participantIds[i],
                swap.participantAmounts[i],
                ""
            );
        }

        for (uint256 i = 0; i < swap.initiatorTokens.length; i++) {
            IERC1155(swap.initiatorTokens[i]).safeTransferFrom(
                address(this),
                swap.participant,
                swap.initiatorIds[i],
                swap.initiatorAmounts[i],
                ""
            );
        }

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
        require(block.timestamp >= swap.startTime + swap.timeLockDuration, "Time lock not expired");

        swap.isRefunded = true;

        for (uint256 i = 0; i < swap.initiatorTokens.length; i++) {
            IERC1155(swap.initiatorTokens[i]).safeTransferFrom(
                address(this),
                swap.initiator,
                swap.initiatorIds[i],
                swap.initiatorAmounts[i],
                ""
            );
        }

        emit SwapRefunded(_swapId, swap.initiator, swap.operator);
    }

    /**
     * @dev Adds an operator.
     * @param operator The address of the operator to add.
     */
    function addOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
    }

    /**
     * @dev Removes an operator.
     * @param operator The address of the operator to remove.
     */
    function removeOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
    }

    /**
     * @dev Pauses the contract.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Implements ERC1155Receiver hook for safe transfers.
     * @param operator The address of the operator.
     * @param from The address of the sender.
     * @param id The token ID.
     * @param value The amount of tokens.


     * @param data Additional data.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Implements ERC1155Receiver hook for batch transfers.
     * @param operator The address of the operator.
     * @param from The address of the sender.
     * @param ids The token IDs.
     * @param values The amounts of tokens.
     * @param data Additional data.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
   - Save the contract code in `contracts/MultiAssetAtomicSwap.sol`.
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

       const MultiAssetAtomicSwap = await hre.ethers.getContractFactory("MultiAssetAtomicSwap");
       const multiAssetAtomicSwap = await MultiAssetAtomicSwap.deploy();

       await multiAssetAtomicSwap.deployed();

       console.log("MultiAssetAtomicSwap deployed to:", multiAssetAtomicSwap.address);
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
   - Create a test file in the `test` folder, e.g., `test/MultiAssetAtomicSwap.test.js`:
     ```javascript
     const { expect } = require("chai");
     const { ethers } = require("hardhat");

     describe("MultiAssetAtomicSwap", function () {
       let swapContract;
       let initiator;
       let participant;
       let operator;
       let initiatorToken;
       let participantToken;

       beforeEach(async function () {
         [initiator, participant, operator] = await ethers.getSigners();

         const ERC1155Mock = await ethers.getContractFactory("ERC1155Mock");
         initiatorToken = await ERC1155Mock.deploy();
         participantToken = await ERC1155Mock.deploy();

         const MultiAssetAtomicSwap = await ethers.getContractFactory("MultiAssetAtomicSwap");
         swapContract = await MultiAssetAtomicSwap.deploy();
         await swapContract.deployed();

         await swapContract.addOperator(operator.address);
       });

       it("Should initiate a multi-asset swap with an operator", async function () {
         const secretHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("secret"));
         const timeLockDuration = 3600; // 1 hour

         await initiatorToken.mint(initiator.address, 1, 100, "");
         await participantToken.mint(participant.address, 1, 200, "");

         await initiatorToken.setApprovalForAll(swapContract.address, true);
         await participantToken.setApprovalForAll(swapContract.address, true);

         await swapContract.initiateSwap(
           participant.address,
           [initiatorToken.address],
           [participantToken.address],
           [1],
           [1],
           [100],
           [200],
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

This setup allows for atomic swaps involving multiple asset types, providing a versatile solution for diverse token exchanges. If you need any additional features or customizations, feel free to ask!