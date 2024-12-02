const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityVaultContract = await ethers.getContractFactory("EquityVaultContract");
  const token = await EquityVaultContract.deploy(
    "0xYourERC20TokenAddressHere", // Replace with the underlying equity token address
    "Equity Vault Token",
    "EVT"
  );
  await token.deployed();

  console.log("Equity Vault Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
