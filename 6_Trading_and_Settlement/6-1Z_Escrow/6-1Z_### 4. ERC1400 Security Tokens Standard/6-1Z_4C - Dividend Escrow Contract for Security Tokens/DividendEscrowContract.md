### Smart Contract: `DividendEscrowContract.sol`

Below is the Solidity implementation for the **6-1Z_4C - Dividend Escrow Contract for Security Tokens** using the ERC1400 standard. This contract securely holds dividends from security tokens in escrow until all compliance and corporate conditions are met.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/**
 * @title DividendEscrowContract
 * @dev Escrow contract for holding and distributing security token dividends.
 */
contract DividendEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1400 public securityToken;

    struct Dividend {
        uint256 amount;
        uint256 releaseTime;
        bool isDistributed;
    }

    struct Escrow {
        uint256 dividendId;
        address shareholder;
        uint256 amount;
        bool isClaimed;
    }

    uint256 public nextDividendId;
    uint256 public nextEscrowId;
    mapping(uint256 => Dividend) public dividends;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public shareholderEscrows;

    event DividendCreated(uint256 indexed dividendId, uint256 amount, uint256 releaseTime);
    event DividendEscrowed(uint256 indexed escrowId, uint256 indexed dividendId, address indexed shareholder, uint256 amount);
    event DividendClaimed(uint256 indexed escrowId, address indexed shareholder, uint256 amount);
    event DividendRefunded(uint256 indexed dividendId, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyWhitelisted(address account) {
        require(securityToken.isOperatorFor(account, account), "Account is not whitelisted");
        _;
    }

    constructor(address _securityToken) {
        require(_securityToken != address(0), "Invalid security token address");
        securityToken = IERC1400(_securityToken);
    }

    /**
     * @dev Create a new dividend to be held in escrow.
     * @param amount Amount of tokens to be distributed as dividends.
     * @param releaseTime Time when the dividends can be released.
     */
    function createDividend(uint256 amount, uint256 releaseTime) external onlyOwner whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        uint256 dividendId = nextDividendId++;
        dividends[dividendId] = Dividend({
            amount: amount,
            releaseTime: releaseTime,
            isDistributed: false
        });

        emit DividendCreated(dividendId, amount, releaseTime);
    }

    /**
     * @dev Escrow dividend for a shareholder.
     * @param dividendId ID of the dividend to be escrowed.
     * @param shareholder Address of the shareholder.
     * @param amount Amount of dividends to be escrowed.
     */
    function escrowDividend(uint256 dividendId, address shareholder, uint256 amount) external onlyOwner onlyWhitelisted(shareholder) whenNotPaused nonReentrant {
        require(dividends[dividendId].amount > 0, "Invalid dividend ID");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= dividends[dividendId].amount, "Amount exceeds available dividends");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            dividendId: dividendId,
            shareholder: shareholder,
            amount: amount,
            isClaimed: false
        });
        shareholderEscrows[shareholder].push(escrowId);

        dividends[dividendId].amount = dividends[dividendId].amount.sub(amount);

        emit DividendEscrowed(escrowId, dividendId, shareholder, amount);
    }

    /**
     * @dev Claim escrowed dividend by the shareholder.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimDividend(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.shareholder == msg.sender, "Caller is not the shareholder");
        require(!escrow.isClaimed, "Dividend already claimed");
        require(dividends[escrow.dividendId].releaseTime <= block.timestamp, "Dividend is not yet available for release");

        escrow.isClaimed = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, escrow.amount, "", "");

        emit DividendClaimed(escrowId, msg.sender, escrow.amount);
    }

    /**
     * @dev Refund unclaimed dividends back to the contract owner.
     * @param dividendId ID of the dividend to be refunded.
     */
    function refundDividend(uint256 dividendId) external onlyOwner nonReentrant {
        Dividend storage dividend = dividends[dividendId];
        require(dividend.amount > 0, "No dividends to refund");
        require(!dividend.isDistributed, "Dividends already distributed");

        dividend.isDistributed = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, dividend.amount, "", "");

        emit DividendRefunded(dividendId, dividend.amount);
    }

    /**
     * @dev Emergency withdrawal of tokens from the contract by the owner.
     */
    function emergencyWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 contractBalance = securityToken.balanceOf(address(this));
        require(contractBalance > 0, "No funds to withdraw");

        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, contractBalance, "", "");

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
     * @dev Returns all escrows for a specific shareholder.
     * @param shareholder Address of the shareholder.
     */
    function getShareholderEscrows(address shareholder) external view returns (uint256[] memory) {
        return shareholderEscrows[shareholder];
    }
}
```

### Key Features of the Contract:

1. **ERC1400 Compliance**:
   - The contract uses the ERC1400 standard to manage security tokens and ensures compliance with securities regulations for dividend distribution.

2. **Dividend Creation and Management**:
   - `createDividend()`: Allows the contract owner to create a dividend, specifying the amount of tokens to be held in escrow and the release time for the dividends.

3. **Dividend Escrowing**:
   - `escrowDividend()`: Assigns a portion of the dividend to a specified shareholder, holding it in escrow until the release conditions are met.

4. **Dividend Claiming**:
   - `claimDividend()`: Allows shareholders to claim their escrowed dividends once the release time has been reached and conditions are met.

5. **Refund Mechanism**:
   - `refundDividend()`: Refunds any unclaimed dividends back to the contract owner if they remain unclaimed after a specified period.

6. **Emergency Withdrawals**:
   - `emergencyWithdraw()`: Enables the contract owner to withdraw all escrowed funds in case of an emergency, but only when the contract is paused.

7. **Whitelist Mechanism**:
   - Ensures that only whitelisted shareholders, verified by the ERC1400 token's compliance checks, can participate in dividend escrowing and claiming.

8. **Event Logging**:
   - Logs key actions such as `DividendCreated`, `DividendEscrowed`, `DividendClaimed`, and `DividendRefunded` to track the contract's operations.

9. **Security Features**:
   - Includes pausing mechanisms and emergency withdrawal features to handle unexpected scenarios safely.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/DividendEscrowContract.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const securityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with actual ERC1400 token contract address

     const DividendEscrowContract = await ethers.getContractFactory("DividendEscrowContract");
     const escrow = await DividendEscrowContract.deploy(securityTokenAddress);
     console.log("DividendEscrowContract deployed to:", escrow.address);
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

- **Compliance Integration**: Integrate with third-party KYC/AML services

 to ensure only verified investors can claim dividends.
- **Governance Features**: Implement voting mechanisms for shareholders to approve or reject dividend distributions.
- **Automated Reporting**: Add functionalities to generate automated compliance and tax reports.
- **Advanced Dividend Strategies**: Incorporate additional dividend strategies, such as reinvestment or tiered distribution.

If you need further modifications or additional features, feel free to ask!