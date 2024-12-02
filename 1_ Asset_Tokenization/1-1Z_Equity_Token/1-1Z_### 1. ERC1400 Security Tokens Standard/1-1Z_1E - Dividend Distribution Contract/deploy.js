const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const equityToken = await EquityToken.deploy();
  await equityToken.deployed();

  const Stablecoin = await ethers.getContractFactory("Stablecoin");
  const stablecoin = await Stablecoin.deploy();
  await stablecoin.deployed();

  console.log("Equity Token deployed to:", equityToken.address);
  console.log("Stablecoin deployed to:", stablecoin.address);

  const DividendDistribution = await ethers.getContractFactory("DividendDistribution");
  const dividendDistribution = await DividendDistribution.deploy(equityToken.address, stablecoin.address);
  await dividendDistribution.deployed();

  console.log("Dividend Distribution Contract deployed to:", dividendDistribution.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
