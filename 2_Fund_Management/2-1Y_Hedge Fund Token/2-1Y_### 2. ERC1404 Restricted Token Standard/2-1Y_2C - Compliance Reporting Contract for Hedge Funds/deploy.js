const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ComplianceReporting = await hre.ethers.getContractFactory("ComplianceReporting");
  const token = await ComplianceReporting.deploy("HedgeFundToken", "HFT", 18);

  await token.deployed();
  console.log("Compliance Reporting Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
