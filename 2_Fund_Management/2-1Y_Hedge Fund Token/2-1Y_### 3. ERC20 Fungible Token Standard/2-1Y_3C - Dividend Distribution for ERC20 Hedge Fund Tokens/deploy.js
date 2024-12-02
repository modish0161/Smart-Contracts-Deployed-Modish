const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const DividendDistribution = await hre.ethers.getContractFactory("DividendDistribution");
  const token = await DividendDistribution.deploy("Hedge Fund Token", "HFT");

  await token.deployed();
  console.log("Dividend Distribution Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
