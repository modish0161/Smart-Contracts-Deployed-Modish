// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const FungibleRealEstateToken = await ethers.getContractFactory("FungibleRealEstateToken");
  const fungibleRealEstateToken = await FungibleRealEstateToken.deploy("Real Estate Token", "RET", ethers.utils.parseUnits("1000000", 18));

  console.log("Fungible Real Estate Token deployed to:", fungibleRealEstateToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
