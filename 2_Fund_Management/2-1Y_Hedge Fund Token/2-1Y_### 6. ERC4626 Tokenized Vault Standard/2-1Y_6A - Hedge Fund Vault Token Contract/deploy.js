const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const Asset = await hre.ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token
  const asset = await Asset.deploy(/* constructor args */);
  await asset.deployed();

  const HedgeFundVaultToken = await hre.ethers.getContractFactory("HedgeFundVaultToken");
  const vaultToken = await HedgeFundVaultToken.deploy(asset.address);

  await vaultToken.deployed();
  console.log("Hedge Fund Vault Token Contract deployed to:", vaultToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
