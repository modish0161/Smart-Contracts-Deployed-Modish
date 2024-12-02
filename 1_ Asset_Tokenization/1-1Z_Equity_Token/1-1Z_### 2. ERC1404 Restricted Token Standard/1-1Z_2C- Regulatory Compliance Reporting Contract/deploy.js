const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const RegulatoryComplianceReporting = await ethers.getContractFactory("RegulatoryComplianceReporting");
  const token = await RegulatoryComplianceReporting.deploy("Compliance Equity Token", "CET", ethers.utils.parseEther("1000000"));
  await token.deployed();

  console.log("Regulatory Compliance Reporting Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
