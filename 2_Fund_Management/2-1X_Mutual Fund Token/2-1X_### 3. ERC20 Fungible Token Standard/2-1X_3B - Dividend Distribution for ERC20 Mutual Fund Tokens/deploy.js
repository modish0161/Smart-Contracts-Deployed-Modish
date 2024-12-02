const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const DividendDistribution = await hre.ethers.getContractFactory("DividendDistribution");
  const dividendToken = await DividendDistribution.deploy(
    "Dividend Mutual Fund Token", // Token name
    "DMFT",                       // Token symbol
    1000000 * 10 ** 18            // Initial supply (1 million tokens)
  );

  await dividendToken.deployed();
  console.log("Dividend Mutual Fund Token deployed to:", dividendToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
