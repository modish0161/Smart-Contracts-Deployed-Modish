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
