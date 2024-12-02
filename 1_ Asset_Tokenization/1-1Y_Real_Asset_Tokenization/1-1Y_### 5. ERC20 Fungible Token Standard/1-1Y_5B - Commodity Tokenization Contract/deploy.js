// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CommodityTokenizationContract = await ethers.getContractFactory("CommodityTokenizationContract");
  const commodityToken = await CommodityTokenizationContract.deploy("Commodity Token", "COMT", ethers.utils.parseUnits("1000000", 18));

  console.log("Commodity Tokenization Contract deployed to:", commodityToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
