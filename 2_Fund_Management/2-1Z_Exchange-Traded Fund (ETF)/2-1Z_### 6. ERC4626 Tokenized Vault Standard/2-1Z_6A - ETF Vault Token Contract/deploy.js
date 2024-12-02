const hre = require("hardhat");

async function main() {
  const ETFVaultToken = await hre.ethers.getContractFactory("ETFVaultToken");
  const etfVaultToken = await ETFVaultToken.deploy();
  await etfVaultToken.deployed();
  console.log("ETF Vault Token Contract deployed to:", etfVaultToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
