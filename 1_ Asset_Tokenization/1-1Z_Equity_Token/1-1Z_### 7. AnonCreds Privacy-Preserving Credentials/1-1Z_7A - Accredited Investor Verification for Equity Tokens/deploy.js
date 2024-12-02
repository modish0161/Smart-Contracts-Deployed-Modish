// deploy.js
const hre = require("hardhat");

async function main() {
  // Compile the contract
  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");

  // Deploy the contract
  const accreditedInvestorVerification = await AccreditedInvestorVerification.deploy();

  // Wait for the contract to be deployed
  await accreditedInvestorVerification.deployed();

  // Log the address of the deployed contract
  console.log("AccreditedInvestorVerification deployed to:", accreditedInvestorVerification.address);
}

// Run the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
