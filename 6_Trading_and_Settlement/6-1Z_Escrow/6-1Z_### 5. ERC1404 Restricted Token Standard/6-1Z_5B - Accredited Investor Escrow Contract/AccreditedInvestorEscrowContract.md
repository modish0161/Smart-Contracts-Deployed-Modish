### Smart Contract: `AccreditedInvestorEscrowContract.sol`

Below is the Solidity implementation for the **6-1Z_5B - Accredited Investor Escrow Contract** using the ERC1404 standard. This contract escrows restricted tokens for accredited investors, ensuring compliance with regulatory requirements before releasing the tokens.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IERC1404.sol";

/**
 * @title AccreditedInvestorEscrowContract
 * @dev Escrow contract for holding and releasing restricted tokens for accredited investors.
 */
contract AccreditedInvestorEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1404 public restrictedToken;

    struct Escrow {
        address sender;
        address recipient;
        uint256 amount;
        uint256 releaseTime;
        bool isClaimed;
        bool isApproved;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event TokensEscrowed(uint256 indexed escrowId, address indexed sender, address indexed recipient, uint256 amount, uint256 releaseTime);
    event TokensClaimed(uint256 indexed escrowId, address indexed recipient, uint256 amount);
    event EscrowApproved(uint256 indexed escrowId);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyAuthorized(address account) {
        require(restrictedToken.detectTransferRestriction(account, account) == 0, "Account is not authorized");
        _;
    }

    constructor(address _restrictedToken) {
        require(_restrictedToken != address(0), "Invalid token address");
        restrictedToken = IERC1404(_restrictedToken);
    }

    /**
     * @dev Escrow tokens for a specified recipient.
     * @param recipient Address of the recipient.
     * @param amount Amount of tokens to be escrowed.
     * @param releaseTime Time when the tokens can be claimed.
     */
    function escrowTokens(address recipient, uint256 amount, uint256 releaseTime) external whenNotPaused onlyAuthorized(msg.sender) nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(restrictedToken.detectTransferRestriction(msg.sender, recipient) == 0, "Transfer restricted");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });
        userEscrows[recipient].push(escrowId);

        restrictedToken.transferFrom(msg.sender, address(this), amount);

        emit TokensEscrowed(escrowId, msg.sender, recipient, amount, releaseTime);
    }

    /**
     * @dev Approve the escrow for release once accreditation checks are satisfied.
     * @param escrowId ID of the escrow to be approved.
     */
    function approveEscrow(uint256 escrowId) external onlyOwner {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isApproved, "Escrow already approved");
        require(restrictedToken.detectTransferRestriction(address(this), escrow.recipient) == 0, "Recipient is not accredited");

        escrow.isApproved = true;

        emit EscrowApproved(escrowId);
    }

    /**
     * @dev Claim escrowed tokens.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimTokens(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.recipient == msg.sender, "Caller is not the recipient");
        require(!escrow.isClaimed, "Tokens already claimed");
        require(escrow.releaseTime <= block.timestamp, "Tokens are not yet available for release");
        require(escrow.isApproved, "Escrow not approved");

        escrow.isClaimed = true;
        restrictedToken.transfer(msg.sender, escrow.amount);

        emit TokensClaimed(escrowId, msg.sender, escrow.amount);
    }

    /**
     * @dev Emergency withdrawal of tokens from the contract by the owner.
     */
    function emergencyWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 contractBalance = restrictedToken.balanceOf(address(this));
        require(contractBalance > 0, "No funds to withdraw");

        restrictedToken.transfer(msg.sender, contractBalance);

        emit EmergencyWithdrawal(msg.sender, contractBalance);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns all escrows for a specific user.
     * @param user Address of the user.
     */
    function getUserEscrows(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }
}
```

### Key Features of the Contract:

1. **ERC1404 Compliance**:
   - The contract uses the ERC1404 standard, ensuring that only accredited investors can participate in the escrow process.

2. **Token Escrowing**:
   - `escrowTokens()`: Allows the sender to escrow tokens for a specific recipient with a specified release time. This function ensures that both the sender and recipient are authorized before escrowing tokens.

3. **Approval Process**:
   - `approveEscrow()`: Enables the contract owner to approve escrows for release after verifying that the recipient is accredited and satisfies other compliance checks.

4. **Token Claiming**:
   - `claimTokens()`: Allows the recipient to claim their escrowed tokens once the release time has been reached, provided the escrow has been approved.

5. **Emergency Withdrawals**:
   - `emergencyWithdraw()`: Enables the contract owner to withdraw all escrowed funds in case of an emergency, but only when the contract is paused.

6. **Security Features**:
   - Includes pausing mechanisms and emergency withdrawal features to handle unexpected scenarios safely.

7. **Event Logging**:
   - Logs key actions such as `TokensEscrowed`, `TokensClaimed`, `EscrowApproved`, and `EmergencyWithdrawal` to track the contract's operations.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/AccreditedInvestorEscrowContract.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const restrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with actual ERC1404 token contract address

     const AccreditedInvestorEscrowContract = await ethers.getContractFactory("AccreditedInvestorEscrowContract");
     const escrow = await AccreditedInvestorEscrowContract.deploy(restrictedTokenAddress);
     console.log("AccreditedInvestorEscrowContract deployed to:", escrow.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Deploy the Contract**:
   Run the deployment script:
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetwork
   ```

5. **Interaction**:
   Use the contract ABI to interact with the deployed contract using a frontend or another script.

### Customization and Further Enhancements:

- **Advanced Compliance Integration**: Integrate with third-party KYC/AML services to automate the verification of investor accreditation.
- **Enhanced Governance**: Add voting mechanisms for accredited investors to approve or reject certain contract actions.
- **Multi-Sig Support**: Implement multi-signature support for more secure contract management.
- **Oracle Integration**: Integrate oracles like Chainlink to verify external conditions, such as real-time accreditation status or market prices, before releasing funds.

If you need further modifications or additional features, feel free to ask!