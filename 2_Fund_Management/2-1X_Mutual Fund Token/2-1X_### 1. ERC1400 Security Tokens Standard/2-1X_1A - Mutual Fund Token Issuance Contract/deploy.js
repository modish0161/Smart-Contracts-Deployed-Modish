const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MutualFundTokenIssuance = await hre.ethers.getContractFactory("MutualFundTokenIssuance");
  const mutualFundToken = await MutualFundTokenIssuance.deploy(
    "Mutual Fund Token", // Token name
    "MFT",              // Token symbol
    1000000 * 10 ** 18, // Initial supply (1 million tokens)
    0.01 * 10 ** 18,    // Token price (0.01 ETH)
    0.1 * 10 ** 18,     // Minimum investment (0.1 ETH)
    10 * 10 ** 18       // Maximum investment (10 ETH)
  );

  await mutualFundToken.deployed();
  console.log("Mutual Fund Token Issuance deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
