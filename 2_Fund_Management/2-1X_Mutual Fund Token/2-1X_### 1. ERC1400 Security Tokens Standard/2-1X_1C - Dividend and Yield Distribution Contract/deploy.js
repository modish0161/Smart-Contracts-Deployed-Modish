const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const DividendAndYieldDistribution = await hre.ethers.getContractFactory("DividendAndYieldDistribution");
  const mutualFundToken = await DividendAndYieldDistribution.deploy(
    "Mutual Fund Dividend Token", // Token name
    "MFD",                       // Token symbol
    1000000 * 10 ** 18           // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Dividend And Yield Distribution Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
