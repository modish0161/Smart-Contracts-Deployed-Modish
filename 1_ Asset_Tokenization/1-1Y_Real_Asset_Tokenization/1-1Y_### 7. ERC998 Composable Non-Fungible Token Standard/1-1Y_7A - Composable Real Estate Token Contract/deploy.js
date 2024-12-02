const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const ComposableRealEstateToken = await ethers.getContractFactory("ComposableRealEstateToken");
  const composableRealEstateToken = await ComposableRealEstateToken.deploy();

  console.log("Composable Real Estate Token Contract deployed to:", composableRealEstateToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
