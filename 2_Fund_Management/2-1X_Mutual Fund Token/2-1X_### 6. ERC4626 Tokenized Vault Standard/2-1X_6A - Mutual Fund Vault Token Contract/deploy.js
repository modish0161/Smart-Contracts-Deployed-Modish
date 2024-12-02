const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const assetTokenAddress = "0xYourAssetTokenAddressHere"; // Set the underlying asset token address

  const MutualFundVault = await hre.ethers.getContractFactory("MutualFundVault");
  const mutualFundVault = await MutualFundVault.deploy(assetTokenAddress, "Mutual Fund Vault", "MFVT");

  await mutualFundVault.deployed();
  console.log("Mutual Fund Vault Token deployed to:", mutualFundVault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
