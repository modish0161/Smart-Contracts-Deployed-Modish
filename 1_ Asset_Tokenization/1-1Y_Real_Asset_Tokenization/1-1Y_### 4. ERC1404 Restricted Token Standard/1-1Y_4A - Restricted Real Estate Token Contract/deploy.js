// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const RestrictedRealEstateToken = await ethers.getContractFactory("RestrictedRealEstateToken");
  const restrictedRealEstateToken = await RestrictedRealEstateToken.deploy("Restricted Real Estate Token", "RRET", 18);

  console.log("Restricted Real Estate Token deployed to:", restrictedRealEstateToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
