const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedMutualFundToken = await hre.ethers.getContractFactory("RestrictedMutualFundToken");
  const mutualFundToken = await RestrictedMutualFundToken.deploy(
    "Restricted Mutual Fund Token", // Token name
    "RMFT",                        // Token symbol
    1000000 * 10 ** 18             // Initial supply (1 million tokens)
  );

  await mutualFundToken.deployed();
  console.log("Restricted Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
