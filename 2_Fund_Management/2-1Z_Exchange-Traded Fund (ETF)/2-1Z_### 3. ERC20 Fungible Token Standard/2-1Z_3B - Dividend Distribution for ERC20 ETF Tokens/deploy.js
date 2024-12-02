const hre = require("hardhat");

async function main() {
  const DividendDistribution = await hre.ethers.getContractFactory("DividendDistribution");
  const dividendDistribution = await DividendDistribution.deploy();
  await dividendDistribution.deployed();
  console.log("Dividend Distribution Contract deployed to:", dividendDistribution.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
