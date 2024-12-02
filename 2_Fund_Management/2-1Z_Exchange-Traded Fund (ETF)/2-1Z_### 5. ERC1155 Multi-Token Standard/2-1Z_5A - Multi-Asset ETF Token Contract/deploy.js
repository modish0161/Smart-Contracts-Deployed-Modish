const hre = require("hardhat");

async function main() {
  const MultiAssetETFToken = await hre.ethers.getContractFactory("MultiAssetETFToken");
  const multiAssetETFToken = await MultiAssetETFToken.deploy("https://api.example.com/metadata/{id}");
  await multiAssetETFToken.deployed();
  console.log("Multi-Asset ETF Token Contract deployed to:", multiAssetETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
