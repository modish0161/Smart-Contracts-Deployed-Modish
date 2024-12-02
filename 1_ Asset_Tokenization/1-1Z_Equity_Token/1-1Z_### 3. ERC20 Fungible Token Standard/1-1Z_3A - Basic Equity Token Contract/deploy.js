const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const BasicEquityToken = await ethers.getContractFactory("BasicEquityToken");
  const token = await BasicEquityToken.deploy("Basic Equity Token", "BET");
  await token.deployed();

  console.log("Basic Equity Token Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
