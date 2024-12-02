const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const equityToken = await EquityToken.deploy();
  await equityToken.deployed();

  console.log("Equity Token deployed to:", equityToken.address);

  const EquityWhitelistingBlacklisting = await ethers.getContractFactory("EquityWhitelistingBlacklisting");
  const equityWhitelistingBlacklisting = await EquityWhitelistingBlacklisting.deploy(equityToken.address);
  await equityWhitelistingBlacklisting.deployed();

  console.log("Equity Whitelisting and Blacklisting Contract deployed to:", equityWhitelistingBlacklisting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
