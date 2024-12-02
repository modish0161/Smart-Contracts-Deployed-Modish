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
