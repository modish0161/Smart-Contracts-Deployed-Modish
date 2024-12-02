const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const equityToken = await EquityToken.deploy();
  await equityToken.deployed();

  console.log("Equity Token deployed to:", equityToken.address);

  const EquityTransferRestrictions = await ethers.getContractFactory("EquityTransferRestrictions");
  const equityTransferRestrictions = await EquityTransferRestrictions.deploy(equityToken.address);
  await equityTransferRestrictions.deployed();

  console.log("Equity Transfer Restrictions Contract deployed to:", equityTransferRestrictions.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
