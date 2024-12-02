const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const LockUpPeriodMutualFund = await hre.ethers.getContractFactory("LockUpPeriodMutualFund");
  const mutualFundToken = await LockUpPeriodMutualFund.deploy(
    "Mutual Fund Lock-Up Token", // Token name
    "MFLT",                      // Token symbol
    1000000 * 10 ** 18           // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Lock-Up Period Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
