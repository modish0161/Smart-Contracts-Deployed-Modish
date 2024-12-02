// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const partitions = [ethers.utils.formatBytes32String("default")]; // Default partition
  const name = "Tokenized Real Estate Security";
  const symbol = "TRES";

  const TokenizedRealEstateSecurity = await ethers.getContractFactory("TokenizedRealEstateSecurity");
  const tokenizedRealEstateSecurity = await TokenizedRealEstateSecurity.deploy(name, symbol, partitions);

  console.log("TokenizedRealEstateSecurity deployed to:", tokenizedRealEstateSecurity.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
