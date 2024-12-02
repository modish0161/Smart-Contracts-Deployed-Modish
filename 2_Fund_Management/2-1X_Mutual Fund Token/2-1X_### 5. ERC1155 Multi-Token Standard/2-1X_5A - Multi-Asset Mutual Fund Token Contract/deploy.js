const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const uri = "https://example.com/api/metadata/{id}.json"; // Set your metadata URI

  const MultiAssetMutualFund = await hre.ethers.getContractFactory("MultiAssetMutualFund");
  const mutualFundToken = await MultiAssetMutualFund.deploy(uri);

  await mutualFundToken.deployed();
  console.log("Multi-Asset Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
