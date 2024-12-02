### Contract Name: `MultiPartyAtomicSwap.sol`

Here's the complete implementation for the **6-1X_1C - Multi-Party Atomic Swap Contract** based on your specifications.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiPartyAtomicSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Swap {
        address[] participants;
        address[] tokens;
        uint256[] amounts;
        bytes32 secretHash;
        bytes32 secret;
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
        address[] participants,
        address[] tokens,
        uint256[] amounts,
        bytes32 secretHash,
        uint256 startTime,
        uint256 timeLockDuration
    );

    event SwapCompleted(
        bytes32 indexed swapId,
        address[] participants,
        bytes32 secret
    );

    event SwapRefunded(
        bytes32 indexed swapId,
        address[] participants
    );

    /**
     * @dev Initiates a new multi-party atomic swap.
     * @param _participants The addresses of the participants.
     * @param _tokens The addresses of the ERC20 tokens to be swapped.
     * @param _amounts The amounts of the tokens to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address[] memory _participants,
        address[] memory _tokens,
        uint256[] memory _amounts,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external nonReentrant {
        require(_participants.length > 1, "Invalid number of participants");
        require(_participants.length == _tokens.length, "Participants and tokens length mismatch");
        require(_tokens.length == _amounts.length, "Tokens and amounts length mismatch");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

        for (uint256 i = 0; i < _participants.length; i++) {
            require(_participants[i] != address(0), "Invalid participant address");
            require(_tokens[i] != address(0), "Invalid token address");
            require(_amounts[i] > 0, "Amount must be greater than 0");
        }

        bytes32 swapId = keccak256(
            abi.encodePacked(_participants, _tokens, _secretHash)
        );

        require(!swaps[swapId].isInitiated, "Swap already initiated");

        swaps[swapId] = Swap({
            participants: _participants,
            tokens: _tokens,
            amounts: _amounts,
            secretHash: _secretHash,
            secret: bytes32(0),
            startTime: block.timestamp,
            timeLockDuration: _timeLockDuration,
            isInitiated: true,
            isCompleted: false,
            isRefunded: false
        });

        for (uint256 i = 0; i < _participants.length; i++) {
            IERC20(_tokens[i]).transferFrom(_participants[i], address(this), _amounts[i]);
        }

        emit SwapInitiated(
            swapId,
            msg.sender,
            _participants,
            _tokens,
            _amounts,
            _secretHash,
            block.timestamp,
            _timeLockDuration
        );
    }

    /**
     * @dev Completes the atomic swap by revealing the secret.
     * @param _swapId The ID of the swap.
     * @param _secret The secret used to complete the swap.
     */
    function completeSwap(bytes32 _swapId, bytes32 _secret) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(keccak256(abi.encodePacked(_secret)) == swap.secretHash, "Invalid secret");

        swap.secret = _secret;
        swap.isCompleted = true;

        for (uint256 i = 0; i < swap.participants.length; i++) {
            IERC20(swap.tokens[i]).transfer(swap.participants[(i + 1) % swap.participants.length], swap.amounts[i]);
        }

        emit SwapCompleted(_swapId, swap.participants, _secret);
    }

    /**
     * @dev Refunds the swap to the participants if the time lock has expired and the swap is not completed.
     * @param _swapId The ID of the swap.
     */
    function refundSwap(bytes32 _swapId) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(block.timestamp >= swap.startTime.add(swap.timeLockDuration), "Time lock not expired");

        swap.isRefunded = true;

        for (uint256 i = 0; i < swap.participants.length; i++) {
            IERC20(swap.tokens[i]).transfer(swap.participants[i], swap.amounts[i]);
        }

        emit SwapRefunded(_swapId, swap.participants);
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
   - Save the contract code in `contracts/MultiPartyAtomicSwap.sol`.
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

       const MultiPartyAtomicSwap = await hre.ethers.getContractFactory("MultiPartyAtomicSwap");
       const multiPartyAtomicSwap = await MultiPartyAtomicSwap.deploy();

       await multiPartyAtomicSwap.deployed();

       console.log("MultiPartyAtomicSwap deployed to:", multiPartyAtomicSwap.address);
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
   - Create a test file in the `test` folder, e.g., `test/MultiPartyAtomicSwap.test.js`:
     ```javascript
     const { expect } = require("chai");
     const { ethers } = require("hardhat");

     describe("MultiPartyAtomicSwap", function () {
       let swapContract;
       let participants;
       let tokens;
       let amounts;

       beforeEach(async function () {
         const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
         participants = await ethers.getSigners();
         tokens = [];
         amounts = [100, 200, 300];

         for (let i = 0; i < amounts.length; i++) {
           const token = await ERC20Mock.deploy(`Token ${i}`, `TK${i}`, 18, 1000000);
           await token.deployed();
           tokens.push(token);
         }

         const MultiPartyAtomicSwap = await ethers.getContractFactory("MultiPartyAtomicSwap");
         swapContract = await MultiPartyAtomicSwap.deploy();
         await swapContract.deployed();
       });

       it("Should initiate a multi-party swap", async function () {
         const secretHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("secret"));
         const timeLockDuration = 3600; // 1 hour

         for (let i = 0; i < participants.length; i++) {
           await tokens[i].transfer(swapContract.address, amounts[i]);
         }

         await swapContract.initiateSwap(
           participants.map(p => p.address),
           tokens.map(t => t.address),
           amounts,
           secretHash,
           timeLockDuration
         );

         const swapId = await swapContract.swaps(ethers.utils.keccak256(
           ethers.utils.defaultAbiCoder.encode(
             ["address[]", "address[]", "bytes32"],
             [participants.map(p => p.address), tokens.map(t => t.address), secretHash]
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
   - You can extend the contract to include features like multi-signature approvals

, oracle price feeds, etc., based on your requirements.

6. **Documentation**:
   - Generate API documentation and provide detailed descriptions of each function, event, and parameter within the contract.

This setup allows for multi-party atomic swaps, enabling complex swaps with multiple participants and assets. If you need any additional features or customizations, feel free to ask!