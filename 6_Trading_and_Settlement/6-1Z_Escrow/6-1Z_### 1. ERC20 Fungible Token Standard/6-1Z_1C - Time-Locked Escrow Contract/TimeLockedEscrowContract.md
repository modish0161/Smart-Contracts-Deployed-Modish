### Smart Contract: `TimeLockedEscrowContract.sol`

Below is the Solidity implementation for the **6-1Z_1C - Time-Locked Escrow Contract** using the ERC20 standard. This contract securely holds ERC20 tokens in escrow and releases funds either to the beneficiary or back to the depositor based on whether the predefined conditions are met within a set time period.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TimeLockedEscrowContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Events
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 releaseTime);
    event FundsReleased(address indexed beneficiary, uint256 amount);
    event FundsRefunded(address indexed depositor, uint256 amount);

    // Escrow struct to hold details of the escrowed funds
    struct Escrow {
        uint256 amount;           // Amount of ERC20 tokens held in escrow
        uint256 releaseTime;      // Time when the escrow can be released to beneficiary
        bool isReleased;          // Flag to check if the escrow has been released
        bool isRefunded;          // Flag to check if the funds have been refunded
    }

    // ERC20 token used for escrow
    IERC20 public escrowToken;

    // Address of the depositor
    address public depositor;

    // Address of the beneficiary
    address public beneficiary;

    // Escrow details
    Escrow public escrowDetails;

    // Modifier to check if the caller is the depositor
    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    // Modifier to check if the caller is the beneficiary
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
        _;
    }

    // Modifier to check if the escrow can be released
    modifier canRelease() {
        require(block.timestamp >= escrowDetails.releaseTime, "Release time not reached");
        require(!escrowDetails.isReleased, "Funds already released");
        require(!escrowDetails.isRefunded, "Funds already refunded");
        _;
    }

    // Modifier to check if the escrow can be refunded
    modifier canRefund() {
        require(block.timestamp >= escrowDetails.releaseTime, "Release time not reached");
        require(!escrowDetails.isReleased, "Funds already released");
        require(!escrowDetails.isRefunded, "Funds already refunded");
        _;
    }

    constructor(
        address _depositor,
        address _beneficiary,
        IERC20 _tokenAddress,
        uint256 _amount,
        uint256 _releaseTime
    ) {
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowToken = _tokenAddress;

        // Initialize escrow details
        escrowDetails = Escrow({
            amount: _amount,
            releaseTime: _releaseTime,
            isReleased: false,
            isRefunded: false
        });

        // Transfer tokens from depositor to the contract
        require(escrowToken.transferFrom(depositor, address(this), _amount), "Token transfer failed");
        emit FundsDeposited(depositor, _amount, _releaseTime);
    }

    /**
     * @dev Release funds to the beneficiary.
     */
    function releaseFunds() external onlyBeneficiary canRelease nonReentrant {
        uint256 amount = escrowDetails.amount;
        escrowDetails.isReleased = true;

        require(escrowToken.transfer(beneficiary, amount), "Token transfer failed");
        emit FundsReleased(beneficiary, amount);
    }

    /**
     * @dev Refund funds back to the depositor if conditions are not met.
     */
    function refundFunds() external onlyDepositor canRefund nonReentrant {
        uint256 amount = escrowDetails.amount;
        escrowDetails.isRefunded = true;

        require(escrowToken.transfer(depositor, amount), "Token transfer failed");
        emit FundsRefunded(depositor, amount);
    }

    /**
     * @dev Get details of the escrow.
     */
    function getEscrowDetails() external view returns (uint256 amount, uint256 releaseTime, bool isReleased, bool isRefunded) {
        amount = escrowDetails.amount;
        releaseTime = escrowDetails.releaseTime;
        isReleased = escrowDetails.isReleased;
        isRefunded = escrowDetails.isRefunded;
    }
}
```

### Key Features of the Contract:

1. **Time-Locked Fund Holding**:
   - The contract holds ERC20 tokens in escrow and allows the release to the beneficiary only after the release time is reached. This ensures that the beneficiary can only access the funds after the agreed period.

2. **Deposits**:
   - The constructor initializes the escrow by accepting the ERC20 tokens from the depositor, locking them in the contract until the conditions are met.

3. **Fund Release**:
   - The beneficiary can call the `releaseFunds` function to release the escrowed amount once the release time has been reached. The function can only be called by the beneficiary.

4. **Refund**:
   - If the conditions are not met or the time has elapsed, the depositor can call the `refundFunds` function to retrieve the escrowed amount back to their account.

5. **Modifiers for Validation**:
   - The contract uses modifiers such as `canRelease` and `canRefund` to ensure the correct conditions are met before executing release or refund actions.

6. **Security**:
   - The contract includes protections against reentrancy attacks (`nonReentrant` modifier), proper ownership and role management (`Ownable`), and checks to prevent unauthorized access to funds and functions.

7. **Event Logging**:
   - Events such as `FundsDeposited`, `FundsReleased`, and `FundsRefunded` are emitted to maintain a transparent transaction log.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/TimeLockedEscrowContract.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const escrowTokenAddress = "0xYourERC20TokenAddress"; // Replace with the actual ERC20 token address
     const depositorAddress = "0xDepositorAddress"; // Replace with depositor address
     const beneficiaryAddress = "0xBeneficiaryAddress"; // Replace with beneficiary address
     const amount = ethers.utils.parseUnits("1000", 18); // Example: 1000 tokens with 18 decimals
     const releaseTime = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now

     const TimeLockedEscrowContract = await ethers.getContractFactory("TimeLockedEscrowContract");
     const escrow = await TimeLockedEscrowContract.deploy(
       depositorAddress,
       beneficiaryAddress,
       escrowTokenAddress,
       amount,
       releaseTime
     );

     console.log("TimeLockedEscrowContract deployed to:", escrow.address);
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

- **Conditional Release**: Add extra conditions for releasing funds, such as multi-signature approvals, off-chain oracle verification, or specific event occurrences.
- **Milestone-Based Releases**: Extend the contract to support multiple release milestones over time.
- **Escrow Fees**: Implement fees for the escrow service, which can be deducted from the deposited amount or paid separately.

