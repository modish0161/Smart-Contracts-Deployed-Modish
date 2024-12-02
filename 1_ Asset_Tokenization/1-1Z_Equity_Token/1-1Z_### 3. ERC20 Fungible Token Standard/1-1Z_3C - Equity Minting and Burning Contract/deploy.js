const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityMintingAndBurning = await ethers.getContractFactory("EquityMintingAndBurning");
  const token = await EquityMintingAndBurning.deploy("Equity Token", "EQT");
  await token.deployed();

  console.log("Equity Minting and Burning Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
