### Contract Name: `AccreditedInvestorAtomicSwap.sol`

Here's the implementation for the **6-1X_5C - Accredited Investor Atomic Swap Contract** based on your specifications:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

contract AccreditedInvestorAtomicSwap is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ACCREDITED_INVESTOR_ROLE = keccak256("ACCREDITED_INVESTOR_ROLE");

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

    event InvestorAccredited(address indexed investor);
    event InvestorUnaccredited(address indexed investor);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Adds an accredited investor.
     * @param investor The address of the investor to be accredited.
     */
    function addAccreditedInvestor(address investor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ACCREDITED_INVESTOR_ROLE, investor);
        emit InvestorAccredited(investor);
    }

    /**
     * @dev Removes an accredited investor.
     * @param investor The address of the investor to be unaccredited.
     */
    function removeAccreditedInvestor(address investor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ACCREDITED_INVESTOR_ROLE, investor);
        emit InvestorUnaccredited(investor);
    }

    /**
     * @dev Initiates an atomic swap between accredited investors.
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
        require(hasRole(ACCREDITED_INVESTOR_ROLE, msg.sender), "Initiator not accredited");
        require(hasRole(ACCREDITED_INVESTOR_ROLE, _participant), "Participant not accredited");
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
     * @dev Completes the atomic swap by revealing the secret.
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

1. **Accredited Investor Verification**: 
   - Only accredited investors, as defined by the `ACCREDITED_INVESTOR_ROLE`, can participate in atomic swaps.

2. **Restricted Token Swap**:
   - Designed for ERC1404 tokens, ensuring that only compliant, accredited participants engage in swaps.

3. **Swap Process**:
   - The initiator locks their tokens in the contract and specifies swap conditions.
   - The participant can complete the swap by revealing the secret.
   - If the swap is not completed within the specified time, it can be refunded.

4. **Roles and Permissions**:
   - Admins can add or remove accredited investors and manage the contract state.

5. **Events**:
   - Events are emitted for every significant action to ensure transparency and traceability.

### Deployment Steps Using Hardhat

1. **Prerequisites**:
   - Install Hardhat and OpenZeppelin contracts:
     ```bash
     npm install --save-dev hardhat @openzeppelin/contracts
     ```

2. **Contract Compilation**:
   - Save the contract code in `contracts/AccreditedInvestorAtomicSwap.sol`.
   - Compile the contract:
     ```bash
     npx hardhat compile
     ```

3. **Deployment Script**:
   - Create a deployment script `scripts/deploy.js`:
     ```javascript
     async function main() {
       const [deployer] = await ethers.getSigners();
       console.log("Deploying contracts with the account:", deployer.address);

       const AccreditedInvestorAtomicSwap = await ethers.getContractFactory("AccreditedInvestorAtomicSwap");
       const accreditedInvestorAtomicSwap = await AccreditedInvestorAtomicSwap.deploy();

       console.log("AccreditedInvestorAtomicSwap deployed to:", accreditedInvestorAtomicSwap.address);
     }

     main().catch((error) => {
       console

.error(error);
       process.exitCode = 1;
     });
     ```

4. **Deploy the Contract**:
   - Deploy the contract to the desired network:
     ```bash
     npx hardhat run scripts/deploy.js --network <network-name>
     ```
   - Replace `<network-name>` with the desired network (e.g., `localhost`, `rinkeby`, `mainnet`).

5. **Testing**:
   - Write test cases for all functions and ensure compliance with expected behavior.
   - Run tests using Hardhat:
     ```bash
     npx hardhat test
     ```

6. **Documentation**:
   - Document the API, user guides, and developer notes for future reference and usage.

Let me know if you need further modifications or additional features!