const hre = require("hardhat");

async function main() {
  const initialSupply = 1000000; // Set initial supply as needed
  const ComplianceReporting = await hre.ethers.getContractFactory("ComplianceReporting");
  const complianceReporting = await ComplianceReporting.deploy(initialSupply);
  await complianceReporting.deployed();
  console.log("Compliance Reporting Contract deployed to:", complianceReporting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
