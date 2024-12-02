const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityTokenRedemption = await ethers.getContractFactory("EquityTokenRedemption");
  const token = await EquityTokenRedemption.deploy("Equity Redemption Token", "ERT", []);
  await token.deployed();

  console.log("Equity Token Redemption Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
