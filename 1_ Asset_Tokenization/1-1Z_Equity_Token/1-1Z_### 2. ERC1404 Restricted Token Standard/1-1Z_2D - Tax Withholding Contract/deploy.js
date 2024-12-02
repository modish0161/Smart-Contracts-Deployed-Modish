const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const TaxWithholding = await ethers.getContractFactory("TaxWithholding");
  const token = await TaxWithholding.deploy("Equity Token", "ETK", ethers.utils.parseEther("1000000"));
  await token.deployed();

  console.log("Tax Withholding Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
