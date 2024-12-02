// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Parameters for deployment
  const vaultTokenAddress = "0xYourVaultTokenAddress"; // ERC20 token address representing shares
  const minInvestment = ethers.utils.parseUnits("500", 18); // Minimum investment

  // Deploy the contract
  const CommodityVaultContract = await ethers.getContractFactory("CommodityVaultContract");
  const vaultContract = await CommodityVaultContract.deploy(vaultTokenAddress, minInvestment);

  console.log("Commodity Vault Contract deployed to:", vaultContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
