const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const DividendDistributionERC20 = await ethers.getContractFactory("DividendDistributionERC20");
  const token = await DividendDistributionERC20.deploy("Dividend Equity Token", "DET");
  await token.deployed();

  console.log("Dividend Distribution Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
