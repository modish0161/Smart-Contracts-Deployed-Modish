const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
  const accreditedInvestorVerification = await AccreditedInvestorVerification.deploy();

  console.log("Accredited Investor Verification Contract deployed to:", accreditedInvestorVerification.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
