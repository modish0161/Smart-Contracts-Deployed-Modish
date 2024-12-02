const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ComposableMutualFundToken = await hre.ethers.getContractFactory("ComposableMutualFundToken");
  const mutualFundToken = await ComposableMutualFundToken.deploy();

  await mutualFundToken.deployed();
  console.log("Composable Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
