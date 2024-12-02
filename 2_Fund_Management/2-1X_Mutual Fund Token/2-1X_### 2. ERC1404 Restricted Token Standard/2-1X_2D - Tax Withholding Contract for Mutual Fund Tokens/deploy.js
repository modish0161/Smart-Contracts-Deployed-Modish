const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TaxWithholdingMutualFund = await hre.ethers.getContractFactory("TaxWithholdingMutualFund");
  const mutualFundToken = await TaxWithholdingMutualFund.deploy(
    "Tax Withholding Mutual Fund Token", // Token name
    "TWMFT",                             // Token symbol
    1000000 * 10 ** 18,                  // Initial supply (1 million tokens)
    500                                  // Initial tax rate (5%)
  );

  await mutualFundToken.deployed();
  console.log("Tax Withholding Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
