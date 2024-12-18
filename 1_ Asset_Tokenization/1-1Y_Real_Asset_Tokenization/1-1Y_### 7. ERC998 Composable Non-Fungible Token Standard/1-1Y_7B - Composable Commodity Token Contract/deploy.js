const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const ComposableCommodityToken = await ethers.getContractFactory("ComposableCommodityToken");
  const composableCommodityToken = await ComposableCommodityToken.deploy();

  console.log("Composable Commodity Token Contract deployed to:", composableCommodityToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
