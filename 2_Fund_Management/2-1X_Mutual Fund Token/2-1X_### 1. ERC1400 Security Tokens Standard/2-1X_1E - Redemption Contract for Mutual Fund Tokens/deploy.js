const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const RedemptionMutualFund = await hre.ethers.getContractFactory("RedemptionMutualFund");
  const mutualFundToken = await RedemptionMutualFund.deploy(
    "Mutual Fund Redemption Token", // Token name
    "MFRT",                         // Token symbol
    1000000 * 10 ** 18              // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Redemption Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
