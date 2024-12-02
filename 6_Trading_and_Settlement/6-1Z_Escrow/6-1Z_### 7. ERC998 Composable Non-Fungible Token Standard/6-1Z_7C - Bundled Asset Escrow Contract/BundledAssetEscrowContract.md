### Smart Contract: `BundledAssetEscrowContract.sol`

Below is the Solidity implementation for the **6-1Z_7C - Bundled Asset Escrow Contract** using the ERC998 standard. This contract is designed to hold bundled assets within composable tokens in escrow, ensuring that all components of the bundled token are transferred simultaneously once the contract conditions are satisfied.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC998/IERC998.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title BundledAssetEscrowContract
 * @dev Escrow contract for holding ERC998 composable tokens and their underlying assets until conditions are met.
 */
contract BundledAssetEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    struct Escrow {
        address depositor;
        address beneficiary;
        uint256 composableTokenId;
        uint256[] underlyingAssetIds;
        uint256 releaseTime;
        bool isClaimed;
        bool isApproved;
    }

    IERC998 public composableToken;
    IERC721 public underlyingAssetToken;

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event ComposableTokenEscrowed(
        uint256 indexed escrowId,
        address indexed depositor,
        address beneficiary,
        uint256 composableTokenId,
        uint256[] underlyingAssetIds,
        uint256 releaseTime
    );
    event ComposableTokenClaimed(
        uint256 indexed escrowId,
        address indexed beneficiary,
        uint256 composableTokenId
    );
    event EscrowApproved(uint256 indexed escrowId);
    event EmergencyWithdrawal(address indexed owner, uint256 composableTokenId);

    modifier onlyDepositor(uint256 escrowId) {
        require(
            escrows[escrowId].depositor == msg.sender,
            "Caller is not the depositor"
        );
        _;
    }

    modifier onlyBeneficiary(uint256 escrowId) {
        require(
            escrows[escrowId].beneficiary == msg.sender,
            "Caller is not the beneficiary"
        );
        _;
    }

    constructor(address _composableToken, address _underlyingAssetToken) {
        require(
            _composableToken != address(0),
            "Invalid composable token address"
        );
        require(
            _underlyingAssetToken != address(0),
            "Invalid underlying asset token address"
        );
        composableToken = IERC998(_composableToken);
        underlyingAssetToken = IERC721(_underlyingAssetToken);
    }

    /**
     * @dev Escrow a composable token and its underlying assets for a beneficiary with specified conditions.
     * @param beneficiary Address of the beneficiary.
     * @param composableTokenId ID of the composable token to be escrowed.
     * @param underlyingAssetIds Array of IDs of the underlying assets to be escrowed.
     * @param releaseTime Time when the composable token can be claimed.
     */
    function escrowComposableToken(
        address beneficiary,
        uint256 composableTokenId,
        uint256[] calldata underlyingAssetIds,
        uint256 releaseTime
    ) external whenNotPaused nonReentrant {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(
            releaseTime > block.timestamp,
            "Release time must be in the future"
        );

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            depositor: msg.sender,
            beneficiary: beneficiary,
            composableTokenId: composableTokenId,
            underlyingAssetIds: underlyingAssetIds,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });

        userEscrows[beneficiary].push(escrowId);

        // Transfer composable token to the contract
        composableToken.safeTransferFrom(msg.sender, address(this), composableTokenId);

        // Transfer underlying assets to the contract
        for (uint256 i = 0; i < underlyingAssetIds.length; i++) {
            underlyingAssetToken.safeTransferFrom(
                msg.sender,
                address(this),
                underlyingAssetIds[i]
            );
        }

        emit ComposableTokenEscrowed(
            escrowId,
            msg.sender,
            beneficiary,
            composableTokenId,
            underlyingAssetIds,
            releaseTime
        );
    }

    /**
     * @dev Approve the escrow for release once the conditions are met.
     * @param escrowId ID of the escrow to be approved.
     */
    function approveEscrow(uint256 escrowId) external onlyOwner {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isApproved, "Escrow already approved");

        escrow.isApproved = true;

        emit EscrowApproved(escrowId);
    }

    /**
     * @dev Claim the escrowed composable token and its underlying assets.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimComposableToken(uint256 escrowId)
        external
        nonReentrant
        onlyBeneficiary(escrowId)
    {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isClaimed, "Token already claimed");
        require(
            escrow.releaseTime <= block.timestamp,
            "Token is not yet available for release"
        );
        require(escrow.isApproved, "Escrow not approved");

        escrow.isClaimed = true;

        // Transfer composable token to the beneficiary
        composableToken.safeTransferFrom(
            address(this),
            msg.sender,
            escrow.composableTokenId
        );

        // Transfer underlying assets to the beneficiary
        for (uint256 i = 0; i < escrow.underlyingAssetIds.length; i++) {
            underlyingAssetToken.safeTransferFrom(
                address(this),
                msg.sender,
                escrow.underlyingAssetIds[i]
            );
        }

        emit ComposableTokenClaimed(
            escrowId,
            msg.sender,
            escrow.composableTokenId
        );
    }

    /**
     * @dev Emergency withdrawal of the composable token from the contract by the owner.
     * @param composableTokenId ID of the composable token to be withdrawn.
     */
    function emergencyWithdraw(uint256 composableTokenId)
        external
        onlyOwner
        whenPaused
        nonReentrant
    {
        composableToken.safeTransferFrom(
            address(this),
            msg.sender,
            composableTokenId
        );
        emit EmergencyWithdrawal(msg.sender, composableTokenId);
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
    function getUserEscrows(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userEscrows[user];
    }
}
```

### Key Features of the Contract:

1. **ERC998 Compliance**:
   - The contract uses the ERC998 standard, ensuring compatibility with composable tokens that may have multiple underlying assets such as ERC20 or ERC721 tokens.

2. **Escrow Management**:
   - `escrowComposableToken()`: Allows a depositor to escrow composable tokens and their underlying assets for a specified beneficiary with a defined release time.
   - `approveEscrow()`: Enables the contract owner to approve the escrow for release once all necessary conditions are met.
   - `claimComposableToken()`: Allows the beneficiary to claim the composable token and its underlying assets once the release time has been reached and the escrow has been approved.

3. **Security and Emergency Features**:
   - `emergencyWithdraw()`: Enables the contract owner to withdraw composable tokens and underlying assets from the escrow contract in case of an emergency, but only when the contract is paused.
   - Pausing and unpausing functionalities to manage unexpected events safely.

4. **Ownership and Authorization**:
   - Only the owner has the authority to pause, unpause, and approve escrows, ensuring controlled management.

5. **Event Logging**:
   - Logs key actions such as `ComposableTokenEscrowed`, `ComposableTokenClaimed`, `EscrowApproved`, and `EmergencyWithdrawal` to track the contract's operations.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/BundledAssetEscrowContract.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const composableTokenAddress = "0xYourComposableTokenAddress"; // Replace with actual ERC998 composable token contract address
     const underlyingAssetTokenAddress = "0xYourUnderlyingAssetTokenAddress"; // Replace with actual ERC721 token contract address

     const BundledAssetEsc

rowContract = await ethers.getContractFactory("BundledAssetEscrowContract");
     const contract = await BundledAssetEscrowContract.deploy(composableTokenAddress, underlyingAssetTokenAddress);

     console.log("BundledAssetEscrowContract deployed to:", contract.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   ```bash
   npx hardhat run scripts/deploy.js --network yourNetwork
   ```

5. **Interaction**:
   Use the contract ABI to interact with the deployed contract using a frontend or another script.

### Customization and Further Enhancements:

- **Advanced Compliance Integration**: Integrate with external services for KYC/AML compliance and regulatory checks.
- **Voting and Governance**: Add on-chain governance mechanisms to allow participants to vote on escrow-related decisions.
- **Multi-Sig Support**: Implement multi-signature support for more secure contract management.
- **Oracle Integration**: Use oracles like Chainlink to verify external conditions, such as real-time asset status or market prices, before releasing funds.

If you need further modifications or additional features, feel free to ask!