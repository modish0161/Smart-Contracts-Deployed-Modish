const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const OperatorControlEquityToken = await ethers.getContractFactory("OperatorControlEquityToken");
  const token = await OperatorControlEquityToken.deploy("Operator Equity Token", "OET", []);
  await token.deployed();

  console.log("Operator Control Equity Token Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
