const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TransferRestrictionsMutualFund = await hre.ethers.getContractFactory("TransferRestrictionsMutualFund");
  const mutualFundToken = await TransferRestrictionsMutualFund.deploy(
    "Mutual Fund Transfer Restricted Token", // Token name
    "MFRT",                                 // Token symbol
    1000000 * 10 ** 18                      // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Transfer Restrictions Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
