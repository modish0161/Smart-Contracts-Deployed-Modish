const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityTokenGovernance = await ethers.getContractFactory("EquityTokenGovernance");
  const token = await EquityTokenGovernance.deploy("Equity Governance Token", "EGT", 1000, 604800);
  await token.deployed();

  console.log("Equity Token Governance Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
