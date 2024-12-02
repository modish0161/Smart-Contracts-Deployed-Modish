const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const InvestorVerificationMutualFund = await hre.ethers.getContractFactory("InvestorVerificationMutualFund");
  const mutualFundToken = await InvestorVerificationMutualFund.deploy(
    "Investor Verification Mutual Fund Token", // Token name
    "IVMFT",                                    // Token symbol
    1000000 * 10 ** 18                          // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Investor Verification Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
