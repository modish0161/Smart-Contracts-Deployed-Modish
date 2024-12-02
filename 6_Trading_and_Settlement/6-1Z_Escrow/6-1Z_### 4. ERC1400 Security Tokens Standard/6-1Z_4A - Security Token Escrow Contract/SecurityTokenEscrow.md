### Smart Contract: `SecurityTokenEscrow.sol`

Below is the Solidity implementation for the **6-1Z_4A - Security Token Escrow Contract** using the ERC1400 standard. This contract ensures compliance with securities regulations and manages security tokens in escrow until the defined conditions are met.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/**
 * @title SecurityTokenEscrow
 * @dev Escrow contract for ERC1400 security tokens, ensuring compliance with securities regulations.
 */
contract SecurityTokenEscrow is Ownable, ReentrancyGuard {
    struct Escrow {
        address seller;
        address buyer;
        uint256 amount;
        bool isComplete;
        bool isRefunded;
        string condition;
        bool conditionMet;
    }

    IERC1400 public securityToken;
    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => bool) public whitelistedInvestors;

    event EscrowCreated(uint256 indexed escrowId, address indexed seller, address indexed buyer, uint256 amount, string condition);
    event ConditionUpdated(uint256 indexed escrowId, string condition, bool status);
    event TokensReleased(uint256 indexed escrowId, address indexed buyer);
    event TokensRefunded(uint256 indexed escrowId, address indexed seller);
    event InvestorWhitelisted(address indexed investor, bool status);

    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Caller is not the seller");
        _;
    }

    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Caller is not the buyer");
        _;
    }

    modifier escrowNotComplete(uint256 escrowId) {
        require(!escrows[escrowId].isComplete, "Escrow already completed");
        require(!escrows[escrowId].isRefunded, "Escrow already refunded");
        _;
    }

    constructor(address _securityToken) {
        require(_securityToken != address(0), "Invalid security token address");
        securityToken = IERC1400(_securityToken);
    }

    /**
     * @dev Adds or removes an investor from the whitelist.
     * @param investor The address of the investor.
     * @param status The whitelist status of the investor.
     */
    function whitelistInvestor(address investor, bool status) external onlyOwner {
        whitelistedInvestors[investor] = status;
        emit InvestorWhitelisted(investor, status);
    }

    /**
     * @dev Creates a new escrow for security tokens.
     * @param buyer Address of the buyer.
     * @param amount The amount of tokens to be held in escrow.
     * @param condition The condition that needs to be met for releasing the tokens.
     */
    function createEscrow(
        address buyer,
        uint256 amount,
        string calldata condition
    ) external nonReentrant {
        require(whitelistedInvestors[buyer], "Buyer is not whitelisted");
        require(securityToken.isOperatorFor(msg.sender, msg.sender), "Seller is not an authorized operator");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            seller: msg.sender,
            buyer: buyer,
            amount: amount,
            isComplete: false,
            isRefunded: false,
            condition: condition,
            conditionMet: false
        });

        // Transfer tokens to the contract
        securityToken.operatorTransferByPartition(bytes32(0), msg.sender, address(this), amount, "", "");

        emit EscrowCreated(escrowId, msg.sender, buyer, amount, condition);
    }

    /**
     * @dev Updates the status of the escrow condition.
     * @param escrowId The ID of the escrow.
     * @param status The status of the condition.
     */
    function updateCondition(uint256 escrowId, bool status) external onlyOwner escrowNotComplete(escrowId) {
        escrows[escrowId].conditionMet = status;
        emit ConditionUpdated(escrowId, escrows[escrowId].condition, status);

        if (status) {
            releaseFunds(escrowId);
        }
    }

    /**
     * @dev Releases the escrowed tokens to the buyer.
     * @param escrowId The ID of the escrow.
     */
    function releaseFunds(uint256 escrowId) internal escrowNotComplete(escrowId) {
        require(escrows[escrowId].conditionMet, "Condition not met");

        Escrow storage escrow = escrows[escrowId];
        escrow.isComplete = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), escrow.buyer, escrow.amount, "", "");

        emit TokensReleased(escrowId, escrow.buyer);
    }

    /**
     * @dev Refunds the escrowed tokens back to the seller.
     * @param escrowId The ID of the escrow.
     */
    function refundFunds(uint256 escrowId) external onlySeller(escrowId) escrowNotComplete(escrowId) nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        escrow.isRefunded = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), escrow.seller, escrow.amount, "", "");

        emit TokensRefunded(escrowId, escrow.seller);
    }

    /**
     * @dev Gets the escrow details.
     * @param escrowId The ID of the escrow.
     */
    function getEscrowDetails(uint256 escrowId)
        external
        view
        returns (
            address seller,
            address buyer,
            uint256 amount,
            bool isComplete,
            bool isRefunded,
            string memory condition,
            bool conditionMet
        )
    {
        Escrow storage escrow = escrows[escrowId];
        return (
            escrow.seller,
            escrow.buyer,
            escrow.amount,
            escrow.isComplete,
            escrow.isRefunded,
            escrow.condition,
            escrow.conditionMet
        );
    }
}
```

### Key Features of the Contract:

1. **ERC1400 Compliance**:
   - The contract is built using the ERC1400 standard, suitable for managing security tokens, ensuring compliance with securities regulations.

2. **Escrow Support for Security Tokens**:
   - Allows for the secure holding of security tokens in escrow until both parties meet predefined conditions. The contract automatically transfers tokens to the buyer when conditions are met and allows for refunds if not.

3. **Whitelist Mechanism**:
   - `whitelistInvestor()`: Adds or removes an investor from the whitelist to ensure only authorized participants can use the escrow.

4. **Deposits and Withdrawals**:
   - `createEscrow()`: Allows the seller to deposit security tokens into the escrow.
   - `updateCondition()`: Allows the contract owner to update the condition status, triggering an automatic fund release if the condition is met.
   - `refundFunds()`: The seller can request a refund of tokens if the conditions are not met or if the escrow needs to be canceled.

5. **Security Features**:
   - Role-based access control ensures that only the seller or contract owner can trigger fund actions.
   - Requires that sellers be authorized operators of the security tokens to create an escrow.

6. **Event Logging**:
   - Logs events such as `EscrowCreated`, `ConditionUpdated`, `TokensReleased`, `TokensRefunded`, and `InvestorWhitelisted` to track key actions in the contract.

7. **Emergency Fallbacks**:
   - The contract supports a refund mechanism, allowing a fallback option for the seller to reclaim their security tokens if necessary.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/SecurityTokenEscrow.sol` and compile it:
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

     const SecurityTokenEscrow = await ethers.getContractFactory("SecurityTokenEscrow");
     const escrow = await SecurityTokenEscrow.deploy(securityTokenAddress);
     console.log("SecurityTokenEscrow contract deployed to:", escrow.address);
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

- **KYC/AML Integration**: Add external service integration to perform KYC/AML checks before allowing participation in the escrow.
- **Governance Features**: Implement token-weighted voting for governance decisions affecting the escrow.
- **Automated Compliance**: Use DAML or similar tools to automate compliance with securities laws.
- **Formal Verification**: Use formal verification tools to ensure the correctness and safety of the contract logic.

If you need any additional features or customization, feel free to ask!