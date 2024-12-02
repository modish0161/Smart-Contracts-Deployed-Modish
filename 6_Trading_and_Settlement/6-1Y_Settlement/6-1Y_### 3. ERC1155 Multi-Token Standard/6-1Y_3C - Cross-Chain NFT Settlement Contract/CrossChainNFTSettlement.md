### Contract Name: `CrossChainNFTSettlement.sol`

Here is the complete Solidity implementation for the **6-1Y_3C - Cross-Chain NFT Settlement Contract** using the ERC1155 standard with cross-chain settlement features.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IBridge {
    function lockTokens(
        address tokenAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        bytes32 destinationChain
    ) external;

    function unlockTokens(
        address tokenAddress,
        address recipient,
        uint256 tokenId,
        uint256 amount,
        bytes32 sourceChain
    ) external;
}

contract CrossChainNFTSettlement is ERC1155, Ownable, ReentrancyGuard, Pausable, ERC1155Supply {
    event CrossChainTradeSettled(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    );

    event CrossChainTradeCreated(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    );

    event TradeCanceled(bytes32 indexed tradeId);

    struct Trade {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 amount;
        bytes32 destinationChain;
        bool isActive;
    }

    mapping(bytes32 => Trade) public trades;
    IBridge public bridge;

    constructor(string memory uri, address bridgeAddress) ERC1155(uri) {
        require(bridgeAddress != address(0), "Invalid bridge address");
        bridge = IBridge(bridgeAddress);
    }

    /**
     * @dev Creates a new cross-chain trade.
     * @param seller Address of the seller.
     * @param buyer Address of the buyer.
     * @param tokenId ID of the NFT being traded.
     * @param amount Amount of the NFT being traded.
     * @param tradeId Unique identifier for the trade.
     * @param destinationChain Identifier of the destination chain.
     */
    function createCrossChainTrade(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 amount,
        bytes32 tradeId,
        bytes32 destinationChain
    ) external whenNotPaused nonReentrant onlyOwner {
        require(seller != address(0) && buyer != address(0), "Invalid seller or buyer address");
        require(trades[tradeId].seller == address(0), "Trade ID already exists");
        require(isApprovedForAll(seller, address(this)), "Contract not approved to transfer seller's tokens");

        trades[tradeId] = Trade({
            seller: seller,
            buyer: buyer,
            tokenId: tokenId,
            amount: amount,
            destinationChain: destinationChain,
            isActive: true
        });

        // Lock tokens on the current chain
        safeTransferFrom(seller, address(this), tokenId, amount, "");
        bridge.lockTokens(address(this), buyer, tokenId, amount, destinationChain);

        emit CrossChainTradeCreated(seller, buyer, tokenId, amount, tradeId, destinationChain);
    }

    /**
     * @dev Completes a cross-chain trade by unlocking tokens on the destination chain.
     * @param tradeId Unique identifier for the trade.
     */
    function settleCrossChainTrade(bytes32 tradeId) external whenNotPaused nonReentrant {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");
        require(trade.buyer == msg.sender, "Only the buyer can settle the trade");

        // Unlock tokens on the destination chain
        bridge.unlockTokens(address(this), trade.buyer, trade.tokenId, trade.amount, trade.destinationChain);

        // Mark trade as inactive
        trade.isActive = false;

        emit CrossChainTradeSettled(trade.seller, trade.buyer, trade.tokenId, trade.amount, tradeId, trade.destinationChain);
    }

    /**
     * @dev Cancels an active cross-chain trade.
     * @param tradeId Unique identifier for the trade.
     */
    function cancelTrade(bytes32 tradeId) external onlyOwner {
        Trade storage trade = trades[tradeId];
        require(trade.isActive, "Trade is not active");

        // Return tokens to the seller
        safeTransferFrom(address(this), trade.seller, trade.tokenId, trade.amount, "");

        // Mark trade as inactive
        trade.isActive = false;

        emit TradeCanceled(tradeId);
    }

    /**
     * @dev Pauses the contract, preventing any cross-chain trades.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing cross-chain trades.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Override required for ERC1155Supply.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }
}
```

### Key Features of the Contract:

1. **Cross-Chain Trade Settlement**:
   - The contract supports cross-chain settlement of NFTs. The `bridge` interface interacts with a cross-chain bridge contract to lock/unlock NFTs across chains.

2. **Trade Creation**:
   - The `createCrossChainTrade` function allows the contract owner to create a cross-chain trade with details such as seller, buyer, token ID, and amount.
   - Each trade is identified and tracked using a unique `tradeId`.

3. **Automatic Settlement**:
   - The `settleCrossChainTrade` function completes the trade by unlocking tokens on the destination chain. Only the buyer can settle the trade, ensuring secure cross-chain transfers.

4. **Trade Cancellation**:
   - The `cancelTrade` function allows the contract owner to cancel an active trade if it is not yet settled. The NFT is returned to the seller, and the trade is marked as inactive.

5. **ERC1155 Integration**:
   - The contract implements ERC1155 functions to handle multi-token transfers and integrates the OpenZeppelin `ERC1155Supply` extension to keep track of token supply.

6. **Pausable**:
   - The contract can be paused and unpaused by the owner to prevent or allow cross-chain trades.

7. **Fallback Protection**:
   - The `receive()` function prevents accidental Ether transfers to the contract.

### Deployment Steps:

1. **Install Dependencies**:
   ```bash
   npm install --save-dev hardhat @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Save the contract in `contracts/CrossChainNFTSettlement.sol` and compile it:
   ```bash
   npx hardhat compile
   ```

3. **Deployment Script**:
   Create a deployment script `scripts/deploy.js`:
   ```javascript
   async function main() {
     const [deployer] = await ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const BridgeAddress = "0xYourBridgeAddress"; // Replace with your bridge contract address
     const uri = "https://api.example.com/metadata/{id}.json"; // Replace with your metadata URI

     const CrossChainNFTSettlement = await ethers.getContractFactory("CrossChainNFTSettlement");
     const crossChainNFTSettlement = await CrossChainNFTSettlement.deploy(uri, BridgeAddress);

     console.log("CrossChainNFTSettlement deployed to:", crossChainNFTSettlement.address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

4. **Deploy the Contract**:
   Deploy the contract to the desired network:
   ```bash
   npx hardhat run scripts/deploy.js --network <network-name>
   ```

5. **Testing**:
   Write unit tests in `test/CrossChainNFTSettlement.test.js` using Mocha/Chai framework to ensure all functionalities work as expected.

6. **API Documentation**:
   Create a detailed API documentation using tools like Docusaurus or similar to document all functions, events, and modifiers for developers.

7. **User Guide**:
   Provide a user guide detailing how to use the contract for creating and settling cross-chain trades, and cancelling trades.

8. **Upgradability**:
   Consider using OpenZeppelin’s `TransparentUpgradeableProxy` or `UUPSUpgradeable` if the contract needs to support upgradability in the future.

### Additional Recommendations:
- **Security Audits**: Ensure the contract undergoes comprehensive security audits before deployment.
- **Cross-Chain Bridge Implementation**: Implement and thoroughly test the cross-chain bridge for seamless NFT transfer between chains.
- **Off-Chain Oracle Integration**: Integrate off-chain oracles for real-time validation of cross-chain transfers.

Let me know if you need further customizations or additional features!