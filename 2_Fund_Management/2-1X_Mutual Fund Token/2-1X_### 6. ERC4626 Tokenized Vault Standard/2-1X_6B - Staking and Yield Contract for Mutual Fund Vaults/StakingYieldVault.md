### Smart Contract: 2-1X_6B_StakingYieldVault.sol

#### Overview
This smart contract uses the ERC4626 standard to create a staking and yield contract for mutual fund vault tokens. It allows investors to stake their mutual fund vault tokens to earn yield based on the performance of the underlying assets. This provides an additional way for token holders to earn returns without directly trading their tokens.

### Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract StakingYieldVault is ERC4626, Ownable, ReentrancyGuard, Pausable {
    IERC20 public immutable rewardToken; // Reward token for yield
    uint256 public rewardRate; // Reward rate in percentage (e.g., 5% = 500)
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardUpdated(uint256 rewardRate);
    event RewardPaid(address indexed user, uint256 reward);
    event Recovered(address token, uint256 amount);

    constructor(
        IERC20 _asset,
        IERC20 _rewardToken,
        string memory name,
        string memory symbol
    ) ERC4626(_asset) ERC20(name, symbol) {
        rewardToken = _rewardToken;
        rewardRate = 500; // Default reward rate as 5%
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
        emit RewardUpdated(_rewardRate);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) /
                totalSupply());
    }

    function earned(address account) public view returns (uint256) {
        return
            ((balanceOf(account) *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
                1e18) + rewards[account];
    }

    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        updateReward(receiver)
        returns (uint256)
    {
        require(assets > 0, "Deposit must be greater than zero");
        uint256 shares = super.deposit(assets, receiver);
        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        override
        nonReentrant
        whenNotPaused
        updateReward(owner)
        returns (uint256)
    {
        require(assets > 0, "Withdraw must be greater than zero");
        uint256 shares = super.withdraw(assets, receiver, owner);
        return shares;
    }

    function claimReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(asset) && tokenAddress != address(rewardToken),
            "Cannot recover vault or reward token"
        );
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}
```

### Contract Explanation:

1. **ERC4626 Vault with Staking and Yield:**
   - The contract is based on the ERC4626 standard, which provides a vault interface for managing pooled assets. This contract extends the vault by allowing investors to stake their vault tokens and earn additional rewards.

2. **Reward Mechanism:**
   - The reward token is a separate ERC20 token. Investors earn rewards based on the number of vault tokens they have staked, calculated using the `rewardRate`.

3. **Constructor Parameters:**
   - The constructor accepts an `IERC20` token as the underlying asset (e.g., a stablecoin or a token representing a mutual fund) and another `IERC20` token as the reward token. It also sets the vault's name and symbol.

4. **Reward Calculation:**
   - The contract calculates rewards using the `rewardPerToken()` function, which is based on the reward rate and the time since the last update.
   - The `earned()` function calculates the rewards for a particular user based on the number of vault tokens they have staked.

5. **Deposit and Withdraw Functions:**
   - The `deposit()` and `withdraw()` functions allow investors to stake and unstake their vault tokens. These functions also update the reward information for the user.

6. **Claim Reward Function:**
   - `claimReward()` allows users to claim their accumulated rewards.

7. **Emergency Functions:**
   - `pause()` and `unpause()` allow the contract owner to pause and unpause the contract in case of emergency, halting all deposits, withdrawals, and reward claims.

8. **Token Recovery:**
   - `recoverERC20()` allows the owner to recover tokens sent to the contract by mistake, except for the asset token and the reward token.

### Deployment Instructions:

1. **Prerequisites:**
   - Ensure you have Node.js and Hardhat installed.
   - Install OpenZeppelin contracts.
     ```bash
     npm install @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder.

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const [deployer] = await hre.ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const assetTokenAddress = "0xYourAssetTokenAddressHere"; // Set the underlying asset token address
     const rewardTokenAddress = "0xYourRewardTokenAddressHere"; // Set the reward token address

     const StakingYieldVault = await hre.ethers.getContractFactory("StakingYieldVault");
     const stakingYieldVault = await StakingYieldVault.deploy(
       assetTokenAddress,
       rewardTokenAddress,
       "Staking Mutual Fund Vault",
       "SMFV"
     );

     await stakingYieldVault.deployed();
     console.log("Staking Mutual Fund Vault deployed to:", stakingYieldVault.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

3. **Run the Deployment Script:**
   ```bash
   npx hardhat run scripts/deploy.js --network [network-name]
   ```

### Testing Suite:

1. **Basic Tests:**
   Use Mocha and Chai for testing core functions, such as deposits, withdrawals, reward calculations, and reward claims.

   ```javascript
   const { expect } = require("chai");

   describe("Staking Yield Vault", function () {
     let stakingYieldVault, assetToken, rewardToken;
     let owner, user1, user2;

     beforeEach(async function () {
       [owner, user1, user2] = await ethers.getSigners();

       const AssetToken = await ethers.getContractFactory("MockERC20");
       assetToken = await AssetToken.deploy("Asset Token", "AST", ethers.utils.parseEther("1000000"));
       await assetToken.deployed();

       const RewardToken = await ethers.getContractFactory("MockERC20");
       rewardToken = await RewardToken.deploy("Reward Token", "RWT", ethers.utils.parseEther("1000000"));
       await rewardToken.deployed();

       const StakingYieldVault = await ethers.getContractFactory("StakingYieldVault");
       stakingYieldVault = await StakingYieldVault.deploy(assetToken.address, rewardToken.address, "Staking Mutual Fund Vault", "SMFV");
       await stakingYieldVault.deployed();
     });

     it("Should allow deposits and mint shares", async function () {
       await assetToken.connect(user1).approve(stakingYieldVault.address, ethers.utils.parseEther("1000"));
       await stakingYieldVault.connect(user1).deposit(ethers.utils.parseEther("1000"), user1.address);

       expect(await stakingYieldVault.balanceOf(user1.address)).to.equal(ethers.utils.parseEther("1000"));
     });

     it("Should calculate rewards correctly", async function () {
       await assetToken.connect(user1).approve(stakingYieldVault.address, ethers.utils.parseEther("1000"));
       await stakingYieldVault.connect(user1).deposit(ethers.utils.parseEther("1000"), user1.address);

       // Advance time by 1 day
       await ethers.provider.send("evm_increaseTime", [86400]);
       await ethers.provider.send("evm_mine");

      

 await stakingYieldVault.connect(user1).claimReward();

       const reward = await rewardToken.balanceOf(user1.address);
       expect(reward).to.be.gt(0);
     });
   });
   ```

2. **Run the Tests:**
   ```bash
   npx hardhat test
   ```

### Documentation:

1. **API Documentation:**
   - Include detailed NatSpec comments for each function, event, and modifier in the contract.

2. **User Guide:**
   - Provide step-by-step instructions on how to interact with the vault, including deposits, withdrawals, and reward claims.

3. **Developer Guide:**
   - Explain the contract architecture, reward mechanism, and customization options for extending the vault's functionalities.

This contract offers a robust solution for mutual fund tokenization and staking using the ERC4626 standard, allowing for efficient asset management, yield generation, and liquidity within the fund.