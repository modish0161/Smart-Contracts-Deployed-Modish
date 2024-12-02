// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const TokenizedRealAssets = await ethers.getContractFactory("TransferRestrictionsRealAssets");
  const tokenizedRealAssets = await TokenizedRealAssets.deploy(
    "Real Asset Security Token",
    "RAST",
    ["partition1", "partition2"]
  );

  console.log("Tokenized Real Assets deployed to:", tokenizedRealAssets.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
