// deploy.js
const hre = require("hardhat");

async function main() {
  // Compile the contract
  const ComposableEquityToken = await hre.ethers.getContractFactory("ComposableEquityToken");

  // Deploy the contract
  const composableEquityToken = await ComposableEquityToken.deploy();

  // Wait for the contract to be deployed
  await composableEquityToken.deployed();

  // Log the address of the deployed contract
  console.log("ComposableEquityToken deployed to:", composableEquityToken.address);
}

// Run the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
