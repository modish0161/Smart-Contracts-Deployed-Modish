const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ComplianceReportingMutualFund = await hre.ethers.getContractFactory("ComplianceReportingMutualFund");
  const mutualFundToken = await ComplianceReportingMutualFund.deploy(
    "Compliance Reporting Mutual Fund Token", // Token name
    "CRMFT",                                   // Token symbol
    1000000 * 10 ** 18                         // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Compliance Reporting Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
