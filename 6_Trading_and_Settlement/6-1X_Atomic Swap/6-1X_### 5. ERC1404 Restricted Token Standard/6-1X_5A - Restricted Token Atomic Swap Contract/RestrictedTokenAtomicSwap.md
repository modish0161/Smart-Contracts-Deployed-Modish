### Contract Name: `RestrictedTokenAtomicSwap.sol`

Here’s the implementation for the **6-1X_5A - Restricted Token Atomic Swap Contract** based on your specifications:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

contract RestrictedTokenAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    struct Swap {
        address initiator;
        address participant;
        address initiatorToken;
        address participantToken;
        uint256 initiatorAmount;
        uint256 participantAmount;
        bytes32 secretHash;
        bytes32 secret;
        uint256 startTime;
        uint256 timeLockDuration;
        bool isInitiated;
        bool isCompleted;
        bool isRefunded;
    }

    mapping(bytes32 => Swap) public swaps;
    mapping(address => bool) public authorizedParticipants;

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
        uint256 timeLockDuration
    );

    event SwapCompleted(
        bytes32 indexed swapId,
        address indexed participant,
        bytes32 secret
    );

    event SwapRefunded(
        bytes32 indexed swapId,
        address indexed initiator
    );

    event ParticipantAuthorized(address indexed participant);
    event ParticipantRevoked(address indexed participant);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    /**
     * @dev Authorizes a participant to engage in restricted token swaps.
     * @param participant The address of the participant to authorize.
     */
    function authorizeParticipant(address participant) external onlyRole(COMPLIANCE_ROLE) {
        authorizedParticipants[participant] = true;
        emit ParticipantAuthorized(participant);
    }

    /**
     * @dev Revokes the authorization of a participant.
     * @param participant The address of the participant to revoke.
     */
    function revokeParticipant(address participant) external onlyRole(COMPLIANCE_ROLE) {
        authorizedParticipants[participant] = false;
        emit ParticipantRevoked(participant);
    }

    /**
     * @dev Initiates a restricted token atomic swap.
     * @param _participant The address of the participant.
     * @param _initiatorToken The address of the initiator's ERC1404 token.
     * @param _participantToken The address of the participant's ERC1404 token.
     * @param _initiatorAmount The amount of the initiator's restricted tokens to be swapped.
     * @param _participantAmount The amount of the participant's restricted tokens to be swapped.
     * @param _secretHash The hash of the secret used for the atomic swap.
     * @param _timeLockDuration The duration for which the swap will be locked.
     */
    function initiateSwap(
        address _participant,
        address _initiatorToken,
        address _participantToken,
        uint256 _initiatorAmount,
        uint256 _participantAmount,
        bytes32 _secretHash,
        uint256 _timeLockDuration
    ) external whenNotPaused nonReentrant {
        require(authorizedParticipants[msg.sender], "Initiator not authorized");
        require(authorizedParticipants[_participant], "Participant not authorized");
        require(_initiatorToken != address(0), "Invalid initiator token address");
        require(_participantToken != address(0), "Invalid participant token address");
        require(_initiatorAmount > 0, "Initiator amount must be greater than 0");
        require(_participantAmount > 0, "Participant amount must be greater than 0");
        require(_secretHash != bytes32(0), "Invalid secret hash");
        require(_timeLockDuration > 0, "Invalid time lock duration");

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
            _timeLockDuration
        );
    }

    /**
     * @dev Completes the restricted token atomic swap by revealing the secret.
     * @param _swapId The ID of the swap.
     * @param _secret The secret used to complete the swap.
     */
    function completeSwap(bytes32 _swapId, bytes32 _secret) external nonReentrant {
        Swap storage swap = swaps[_swapId];

        require(swap.isInitiated, "Swap not initiated");
        require(!swap.isCompleted, "Swap already completed");
        require(!swap.isRefunded, "Swap already refunded");
        require(
            msg.sender == swap.participant,
            "Only participant can complete the swap"
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

        emit SwapCompleted(_swapId, msg.sender, _secret);
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
            msg.sender == swap.initiator,
            "Only initiator can refund the swap"
        );
        require(block.timestamp >= swap.startTime + swap.timeLockDuration, "Time lock not expired");

        swap.isRefunded = true;

        IERC20(swap.initiatorToken).transfer(
            swap.initiator,
            swap.initiatorAmount
        );

        emit SwapRefunded(_swapId, swap.initiator);
    }

    /**
     * @dev Adds a compliance verifier.
     * @param verifier The address of the verifier to add.
     */
    function addComplianceVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(COMPLIANCE_ROLE, verifier);
    }

    /**
     * @dev Removes a compliance verifier.
     * @param verifier The address of the verifier to remove.
     */
    function removeComplianceVerifier(address verifier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(COMPLIANCE_ROLE, verifier);
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

1. **Participant Authorization**: 
   - Only authorized participants can initiate or engage in swaps, ensuring compliance with restrictions.
   
2. **Restricted Token Swap**:
   - Designed for ERC1404 tokens, ensuring that only compliant, accredited participants engage in swaps.

3. **Compliance Verifier Role**:
   - Compliance verifiers manage and oversee authorization, ensuring that only verified entities can engage in swaps.

4. **Swap Process**:
   - The initiator locks their tokens in the contract and specifies swap conditions.
   - The participant can complete the swap by revealing the secret.
   - If the swap is not completed within the specified time, it can be refunded.

5. **Events**:
   - Events are emitted for every significant action to ensure transparency and traceability.

### Deployment Steps Using Hardhat

1. **Prerequisites**:
   - Install Hardhat and OpenZeppelin contracts:
     ```bash
     npm install --save-dev hardhat @openzeppelin/contracts
     ```

2. **Contract Compilation**:
   - Save the contract code in `contracts/RestrictedTokenAtomicSwap.sol`.
   - Compile the contract:
     ```bash
     npx hardhat compile
     ```

3. **Deployment Script**:
   - Create a deployment script in the `scripts` folder, e.g., `scripts/deploy.js`:
     ```javascript
     const hre = require("

hardhat");

     async function main() {
       const [deployer] = await hre.ethers.getSigners();
       console.log("Deploying contracts with the account:", deployer.address);

       const RestrictedTokenAtomicSwap = await hre.ethers.getContractFactory("RestrictedTokenAtomicSwap");
       const restrictedTokenAtomicSwap = await RestrictedTokenAtomicSwap.deploy();

       await restrictedTokenAtomicSwap.deployed();

       console.log("RestrictedTokenAtomicSwap deployed to:", restrictedTokenAtomicSwap.address);
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

4. **Testing**:
   - Create tests for functions like `initiateSwap`, `completeSwap`, `refundSwap`, and participant authorization.
   - Run tests using Hardhat:
     ```bash
     npx hardhat test
     ```

5. **Upgradability**:
   - Consider using a proxy pattern for future upgrades.

Feel free to modify or add more features based on specific requirements. If you need further adjustments or more complex features, let me know!