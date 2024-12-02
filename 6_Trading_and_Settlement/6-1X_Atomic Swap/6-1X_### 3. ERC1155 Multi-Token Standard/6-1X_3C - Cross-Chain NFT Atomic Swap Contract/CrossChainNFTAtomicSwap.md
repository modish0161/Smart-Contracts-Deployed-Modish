### Contract Name: `CrossChainNFTAtomicSwap.sol`

Here’s the complete implementation for the **6-1X_3C - Cross-Chain NFT Atomic Swap Contract** based on your specifications.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CrossChainNFTAtomicSwap is AccessControl, ReentrancyGuard, Pausable, ERC1155Holder {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorToken;
        address participantToken;
        uint256 initiatorId;
        uint256 participantId;
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
        uint256 initiatorId,
        uint256 participantId,
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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Initiates a new cross-chain NFT atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC1155 token.
     * @param _participantToken The address of the participant's ERC1155 token.
     * @param _initiatorId The token ID of the initiator's NFT.
     * @param _participantId The token ID of the participant's NFT.
     * @param _initiatorAmount The amount of the initiator's NFT to be swapped.
     * @param _participantAmount The amount of the participant's NFT to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     * @param _operator The address of the authorized operator.
     */
    function initiateSwap(
        address _participant,
        address _initiatorToken,
        address _participantToken,
        uint256 _initiatorId,
        uint256 _participantId,
        uint256 _initiatorAmount,
        uint256 _participantAmount,
        bytes32 _secretHash,
        uint256 _timeLockDuration,
        address _operator
    ) external whenNotPaused nonReentrant {
        require(_participant != address(0), "Invalid participant address");
        require(_initiatorToken != address(0), "Invalid initiator token address");
        require(_participantToken != address(0), "Invalid participant token address");
        require(_initiatorAmount > 0, "Initiator amount must be greater than 0");
        require(_participantAmount > 0, "Participant amount must be greater than 0");
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
            initiatorToken: _initiatorToken,
            participantToken: _participantToken,
            initiatorId: _initiatorId,
            participantId: _participantId,
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

        IERC1155(_initiatorToken).safeTransferFrom(msg.sender, address(this), _initiatorId, _initiatorAmount, "");

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participant,
            _initiatorToken,
            _participantToken,
            _initiatorId,
            _participantId,
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

        IERC1155(swap.participantToken).safeTransferFrom(
            swap.participant,
            swap.initiator,
            swap.participantId,
            swap.participantAmount,
            ""
        );

        IERC1155(swap.initiatorToken).safeTransferFrom(
            address(this),
            swap.participant,
            swap.initiatorId,
            swap.initiatorAmount,
            ""
        );

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

        IERC1155(swap.initiatorToken).safeTransferFrom(
            address(this),
            swap.initiator,
            swap.initiatorId,
            swap.initiatorAmount,
            ""
        );

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
    ) public virtual override returns (bytes4)

 {
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
   - Save the contract code in `contracts/CrossChainNFTAtomicSwap.sol`.
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

       const CrossChainNFTAtomicSwap = await hre.ethers.getContractFactory("CrossChainNFTAtomicSwap");
       const crossChainNFTAtomicSwap = await CrossChainNFTAtomicSwap.deploy();

       await crossChainNFTAtomicSwap.deployed();

       console.log("CrossChainNFTAtomicSwap deployed to:", crossChainNFTAtomicSwap.address);
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
   - Create a test file in the `test` folder, e.g., `test/CrossChainNFTAtomicSwap.test.js`:
     ```javascript
     const { expect } = require("chai");
     const { ethers } = require("hardhat");

     describe("CrossChainNFTAtomicSwap", function () {
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

         const CrossChainNFTAtomicSwap = await ethers.getContractFactory("CrossChainNFTAtomicSwap");
         swapContract = await CrossChainNFTAtomicSwap.deploy();
         await swapContract.deployed();

         await swapContract.addOperator(operator.address);
       });

       it("Should initiate a cross-chain NFT atomic swap with an operator", async function () {
         const secretHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("secret"));
         const timeLockDuration = 3600; // 1 hour

         await initiatorToken.mint(initiator.address, 1, 1, "");
         await participantToken.mint(participant.address, 1, 1, "");

         await initiatorToken.setApprovalForAll(swapContract.address, true);
         await participantToken.setApprovalForAll(swapContract.address, true);

         await swapContract.initiateSwap(
           participant.address,
           initiatorToken.address,
           participantToken.address,
           1,
           1,
           1,
           1,
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

This setup allows for cross-chain NFT atomic swaps, ensuring secure and simultaneous transfers of NFTs across different blockchain networks. If you need any additional features or customizations, feel free to ask!