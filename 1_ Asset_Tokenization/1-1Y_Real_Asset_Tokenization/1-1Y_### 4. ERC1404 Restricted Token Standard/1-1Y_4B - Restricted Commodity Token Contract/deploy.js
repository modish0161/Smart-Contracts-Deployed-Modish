// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const RestrictedCommodityToken = await ethers.getContractFactory("RestrictedCommodityToken");
  const restrictedCommodityToken = await RestrictedCommodityToken.deploy("Restricted Commodity Token", "RCT", 18);

  console.log("Restricted Commodity Token deployed to:", restrictedCommodityToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
