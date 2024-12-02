const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const defaultOperators = [deployer.address]; // List of initial operators

  const DividendAndProfitSharing = await hre.ethers.getContractFactory("DividendAndProfitSharing");
  const mutualFundToken = await DividendAndProfitSharing.deploy(
    "Advanced Mutual Fund Token", // Token name
    "AMFT",                       // Token symbol
    defaultOperators              // Default operators
  );

  await mutualFundToken.deployed();
  console.log("Dividend and Profit Sharing Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
