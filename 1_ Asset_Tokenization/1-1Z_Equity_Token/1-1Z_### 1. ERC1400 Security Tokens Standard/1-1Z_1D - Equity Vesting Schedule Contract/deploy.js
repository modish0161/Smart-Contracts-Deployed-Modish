const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const equityToken = await EquityToken.deploy();
  await equityToken.deployed();

  console.log("Equity Token deployed to:", equityToken.address);

  const EquityVestingSchedule = await ethers.getContractFactory("EquityVestingSchedule");
  const equityVestingSchedule = await EquityVestingSchedule.deploy(equityToken.address);
  await equityVestingSchedule.deployed();

  console.log("Equity Vesting Schedule Contract deployed to:", equityVestingSchedule.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
