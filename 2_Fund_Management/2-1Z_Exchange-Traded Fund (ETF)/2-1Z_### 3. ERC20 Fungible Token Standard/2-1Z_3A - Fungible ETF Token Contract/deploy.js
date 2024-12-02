const hre = require("hardhat");

async function main() {
  const FungibleETFToken = await hre.ethers.getContractFactory("FungibleETFToken");
  const fungibleETFToken = await FungibleETFToken.deploy();
  await fungibleETFToken.deployed();
  console.log("Fungible ETF Token deployed to:", fungibleETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
