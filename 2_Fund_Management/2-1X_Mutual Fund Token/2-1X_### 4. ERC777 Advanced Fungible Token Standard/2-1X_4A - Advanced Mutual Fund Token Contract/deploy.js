const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const defaultOperators = [deployer.address]; // List of initial operators

  const AdvancedMutualFundToken = await hre.ethers.getContractFactory("AdvancedMutualFundToken");
  const mutualFundToken = await AdvancedMutualFundToken.deploy(
    "Advanced Mutual Fund Token", // Token name
    "AMFT",                       // Token symbol
    defaultOperators              // Default operators
  );

  await mutualFundToken.deployed();
  console.log("Advanced Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
