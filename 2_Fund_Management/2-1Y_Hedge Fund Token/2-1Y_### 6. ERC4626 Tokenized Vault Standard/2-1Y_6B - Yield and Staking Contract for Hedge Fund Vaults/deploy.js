const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const Asset = await hre.ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token
  const asset = await Asset.deploy(/* constructor args */);
  await asset.deployed();

  const initialYieldBPS = 500; // Example yield of 5%
  const YieldAndStakingContract = await hre.ethers.getContractFactory("YieldAndStakingContract");
  const vaultContract = await YieldAndStakingContract.deploy(asset.address, initialYieldBPS);

  await vaultContract.deployed();
  console.log("Yield and Staking Contract deployed to:", vaultContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
