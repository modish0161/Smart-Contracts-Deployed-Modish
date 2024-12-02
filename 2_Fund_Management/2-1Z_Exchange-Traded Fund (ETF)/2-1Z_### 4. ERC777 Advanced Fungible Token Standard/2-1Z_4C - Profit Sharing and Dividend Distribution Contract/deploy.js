const hre = require("hardhat");

async function main() {
  const defaultOperators = []; // Add default operators if necessary
  const ProfitSharingAndDividendDistribution = await hre.ethers.getContractFactory("ProfitSharingAndDividendDistribution");
  const profitSharingAndDividendDistribution = await ProfitSharingAndDividendDistribution.deploy("ETF Token", "ETFT", defaultOperators);
  await profitSharingAndDividendDistribution.deployed();
  console.log("Profit Sharing and Dividend Distribution Contract deployed to:", profitSharingAndDividendDistribution.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
