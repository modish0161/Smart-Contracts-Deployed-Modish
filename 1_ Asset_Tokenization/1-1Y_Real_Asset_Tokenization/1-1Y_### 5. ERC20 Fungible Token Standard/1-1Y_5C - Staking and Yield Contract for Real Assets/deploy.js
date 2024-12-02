// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const initialSupply = ethers.utils.parseUnits("1000000", 18); // 1,000,000 tokens
  const apyRate = 5; // 5% APY
  const rewardDuration = 31536000; // 1 year in seconds

  const StakingAndYieldRealAssetToken = await ethers.getContractFactory("StakingAndYieldRealAssetToken");
  const stakingToken = await StakingAndYieldRealAssetToken.deploy("Real Asset Token", "RAT", initialSupply, apyRate, rewardDuration);

  console.log("Staking and Yield Contract deployed to:", stakingToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
