### Contract Name: `ComplianceDrivenAtomicSwap.sol`

Here’s the complete implementation for the **6-1X_4B - Compliance-Driven Atomic Swap Contract** based on your specifications.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ComplianceDrivenAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant COMPLIANCE_VERIFIER_ROLE = keccak256("COMPLIANCE_VERIFIER_ROLE");

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
    mapping(address => bool) public verifiedInvestors;

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

    event InvestorVerified(address indexed investor);
    event InvestorRevoked(address indexed investor);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Verifies an investor, allowing them to participate in compliant swaps.
     * @param investor The address of the investor to verify.
     */
    function verifyInvestor(address investor) external onlyRole(COMPLIANCE_VERIFIER_ROLE) {
        verifiedInvestors[investor] = true;
        emit InvestorVerified(investor);
    }

    /**
     * @dev Revokes verification of an investor.
     * @param investor The address of the investor to revoke.
     */
    function revokeInvestor(address investor) external onlyRole(COMPLIANCE_VERIFIER_ROLE) {
        verifiedInvestors[investor] = false;
        emit InvestorRevoked(investor);
    }

    /**
     * @dev Initiates a new compliance-driven atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC1400 token.
     * @param _participantToken The address of the participant's ERC1400 token.
     * @param _initiatorAmount The amount of the initiator's security tokens to be swapped.
     * @param _participantAmount The amount of the participant's security tokens to be swapped.
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
        require(verifiedInvestors[msg.sender], "Initiator is not a verified investor");
        require(verifiedInvestors[_participant], "Participant is not a verified investor");

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

        IERC20(_initiatorToken).transferFrom(msg.sender, address(this), _initiatorAmount);

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

        IERC20(swap.participantToken).transferFrom(
            swap.participant,
            swap.initiator,
            swap.participantAmount
        );

        IERC20(swap.initiatorToken).transfer(
            swap.participant,
            swap.initiatorAmount
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

        IERC20(swap.initiatorToken).transfer(
            swap.initiator,
            swap.initiatorAmount
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
}
```

### Key Features

1. **Compliance Verification**: 
   - Verified investors can only participate in swaps.
   - Compliance verifiers can add or revoke verification status for investors.

2. **Operator-Driven Swaps**:
   - The swap can be managed by authorized operators for added control.

3. **Swap Process**:
   - The initiator locks their tokens in the contract and specifies swap conditions.
   - The participant can complete the swap by revealing the secret or it can be managed by the operator.
   - If the swap is not completed within the specified time, it can be refunded.

4. **Events**:
   - Events are emitted for every important action to ensure transparency.

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
   - Save the contract code in `contracts/ComplianceDrivenAtomicSwap.sol`.
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

       const ComplianceDrivenAtomicSwap = await hre.ethers.getContractFactory("ComplianceDrivenAtomicSwap");
       const complianceDrivenAtomicSwap = await ComplianceDrivenAtomicSwap.deploy();

       await complianceDrivenAtomicSwap.deployed();

       console.log("ComplianceDrivenAtomicSwap deployed to:", complianceDrivenAtomicSwap.address);
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
   - Create a test file in the `test` folder, e.g., `test/ComplianceDrivenAtomicSwap.test.js`:
     ```javascript
     const { expect } = require("chai");
     const { ethers } = require("hardhat");

     describe("ComplianceDrivenAtomicSwap", function () {
       let swapContract;
       let initiator;
       let participant;
       let operator;
       let complianceVerifier;
       let initiatorToken;
       let participantToken;

       beforeEach(async function () {
         [initiator, participant, operator, complianceVerifier] = await ethers.getSigners();

         const ERC1400Mock = await ethers.getContractFactory("ERC1400Mock");
         initiatorToken = await ERC1400Mock.deploy();
         participantToken = await ERC1400Mock.deploy();

         const ComplianceDrivenAtomicSwap = await ethers.getContractFactory("ComplianceDrivenAtomicSwap");
         swapContract = await ComplianceDrivenAtomicSwap.deploy();
         await swapContract.deployed();

         await swapContract.addOperator(operator.address);
         await swapContract.grantRole(swapContract.COMPLIANCE_VERIFIER_ROLE(), complianceVerifier.address);

         await swapContract.connect(complianceVerifier).verifyInvestor(initiator.address);
         await swapContract.connect(complianceVerifier).verifyInvestor(participant.address);
       });

       it("Should initiate a compliance-driven atomic swap with a verified investor", async function () {
         const secretHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("secret"));
         const timeLockDuration = 3600; // 1 hour

         await initiatorToken.mint(initiator.address, 1000);
         await participantToken.mint(participant.address, 2000);

         await initiatorToken.approve(swapContract.address, 1000);
         await participantToken.approve(swapContract.address, 2000);

         await swapContract.initiateSwap(
           participant.address,
           initiatorToken.address,
           participantToken.address,
           1000,
           2000,
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

This setup ensures compliance for atomic swaps of security tokens, verifying that only authorized participants can engage in swaps according to regulatory standards. If you need any additional features or customizations, feel free to ask!