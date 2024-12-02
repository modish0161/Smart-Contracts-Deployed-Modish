// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const partitions = [ethers.utils.formatBytes32String("default")]; // Default partition
  const name = "Tokenized Commodity Security";
  const symbol = "TCS";

  const TokenizedCommoditySecurity = await ethers.getContractFactory("TokenizedCommoditySecurity");
  const tokenizedCommoditySecurity = await TokenizedCommoditySecurity.deploy(name, symbol, partitions);

  console.log("TokenizedCommoditySecurity deployed to:", tokenizedCommoditySecurity.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
