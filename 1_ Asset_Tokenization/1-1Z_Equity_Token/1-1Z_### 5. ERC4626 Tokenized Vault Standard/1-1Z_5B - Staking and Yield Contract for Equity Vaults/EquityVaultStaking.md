### Smart Contract: `EquityVaultStaking.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Staking and Yield Contract for Equity Vaults
/// @notice This contract allows equity token holders to stake their equity in a vault and earn yield or dividends.
contract EquityVaultStaking is ERC4626, ERC20Permit, Ownable, ReentrancyGuard, Pausable {
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Event emitted when rewards are added to the contract
    event RewardAdded(uint256 reward);

    // Event emitted when a user stakes their tokens
    event Staked(address indexed user, uint256 amount);

    // Event emitted when a user withdraws their tokens
    event Withdrawn(address indexed user, uint256 amount);

    // Event emitted when a user claims their rewards
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Constructor to initialize the staking contract
    /// @param asset The underlying asset (equity token) of the vault
    /// @param rewardTokenAddress The address of the reward token
    /// @param rewardRatePerSecond The rate at which rewards are distributed per second
    /// @param name The name of the staking vault token
    /// @param symbol The symbol of the staking vault token
    constructor(
        IERC20 asset,
        IERC20 rewardTokenAddress,
        uint256 rewardRatePerSecond,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) ERC20Permit(name) {
        rewardToken = rewardTokenAddress;
        rewardRate = rewardRatePerSecond;
        lastUpdateTime = block.timestamp;
    }

    /// @notice Function to update reward variables before state-changing actions
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /// @notice Function to stake equity tokens in the vault
    /// @param assets The amount of equity tokens to stake
    /// @param receiver The address that will receive the staking shares
    /// @return The amount of staking shares minted
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused updateReward(receiver) returns (uint256) {
        emit Staked(receiver, assets);
        return super.deposit(assets, receiver);
    }

    /// @notice Function to withdraw staked equity tokens from the vault
    /// @param shares The amount of staking shares to withdraw
    /// @param receiver The address that will receive the withdrawn equity tokens
    /// @param owner The address of the owner of the staking shares
    /// @return The amount of underlying assets withdrawn
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant whenNotPaused updateReward(owner) returns (uint256) {
        emit Withdrawn(owner, shares);
        return super.redeem(shares, receiver, owner);
    }

    /// @notice Function to calculate the reward per token staked
    /// @return The reward per token staked
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalSupply());
    }

    /// @notice Function to calculate the amount of rewards earned by a user
    /// @param account The address of the user
    /// @return The amount of rewards earned
    function earned(address account) public view returns (uint256) {
        return ((balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    /// @notice Function to claim earned rewards
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Function to notify the contract about new rewards
    /// @param reward The amount of reward tokens to be added
    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        rewardToken.transferFrom(msg.sender, address(this), reward);
        emit RewardAdded(reward);
    }

    /// @notice Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {}

    /// @notice Override required by Solidity for ERC4626 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **ERC4626 Tokenized Vault Standard**:
   - Inherits from the `ERC4626` standard, creating a vault for equity tokens, enabling tokenization of a basket of equity assets.

2. **Staking and Yield**:
   - `deposit(uint256 assets, address receiver)`: Allows users to stake their equity tokens and receive staking shares.
   - `redeem(uint256 shares, address receiver, address owner)`: Allows users to redeem their staking shares and withdraw their equity tokens.
   - `rewardPerToken()`: Calculates the reward per token staked.
   - `earned(address account)`: Calculates the rewards earned by a user.
   - `getReward()`: Allows users to claim their earned rewards.

3. **Reward Token Management**:
   - `rewardToken`: The ERC20 token used for rewards.
   - `rewardRate`: The rate at which rewards are distributed per second.
   - `notifyRewardAmount(uint256 reward)`: Allows the owner to add rewards to the contract.

4. **Security and Governance**:
   - Uses `Ownable`, `ReentrancyGuard`, and `Pausable` from OpenZeppelin to manage access control, prevent reentrancy attacks, and allow pausing of the contract in emergencies.

5. **Emergency Controls**:
   - `pause()`: Allows the owner to pause all token transfers, deposits, and redemptions.
   - `unpause()`: Allows the owner to unpause the contract.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the contract using Hardhat or Truffle:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Example Hardhat deployment script:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const EquityVaultStaking = await ethers.getContractFactory("EquityVaultStaking");
     const stakingVault = await EquityVaultStaking.deploy(
       "0xYourEquityTokenAddressHere", // Replace with the underlying equity token address
       "0xYourRewardTokenAddressHere", // Replace with the reward token address
       ethers.utils.parseUnits("0.001", 18), // Reward rate per second, e.g., 0.001 tokens/second
       "Staking Vault Token",
       "SVT"
     );
     await stakingVault.deployed();

     console.log("Equity Vault Staking Contract deployed to:", stakingVault.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4. **Run the Deployment Script**:
   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Auditing**:
   - Write test cases to ensure that the staking and reward distribution functionalities work as expected.
   - Verify that the rewards are correctly calculated and distributed to stakers.
   - Test the pause and unpause functionalities to ensure contract security in emergency situations.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Add more complex reward distribution mechanisms, such as time-based multipliers or vesting schedules.
   - Integrate with external protocols for additional yield generation.
   - Implement a governance mechanism allowing stakeholders to vote on reward rates or the inclusion of new assets in the vault.

This contract provides a robust and

 flexible mechanism for allowing equity token holders to stake their assets and earn rewards, enabling a new level of functionality for tokenized equity investments.