const hre = require("hardhat");

async function main() {
  const AssetBundlingContract = await hre.ethers.getContractFactory("AssetBundlingContract");
  const assetBundlingContract = await AssetBundlingContract.deploy();
  await assetBundlingContract.deployed();
  console.log("Asset Bundling Contract deployed to:", assetBundlingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
