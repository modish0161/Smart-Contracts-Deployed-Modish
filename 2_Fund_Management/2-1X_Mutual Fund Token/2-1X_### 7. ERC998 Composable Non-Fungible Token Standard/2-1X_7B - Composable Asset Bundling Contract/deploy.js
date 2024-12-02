const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ComposableAssetBundling = await hre.ethers.getContractFactory("ComposableAssetBundling");
  const composableAssetBundling = await ComposableAssetBundling.deploy();

  await composableAssetBundling.deployed();
  console.log("Composable Asset Bundling deployed to:", composableAssetBundling.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
