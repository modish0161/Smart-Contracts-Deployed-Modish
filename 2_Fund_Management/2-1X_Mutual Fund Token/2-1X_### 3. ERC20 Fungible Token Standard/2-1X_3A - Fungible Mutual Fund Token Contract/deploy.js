const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const FungibleMutualFundToken = await hre.ethers.getContractFactory("FungibleMutualFundToken");
  const mutualFundToken = await FungibleMutualFundToken.deploy(
    "Fungible Mutual Fund Token", // Token name
    "FMFT",                       // Token symbol
    1000000 * 10 ** 18,           // Initial supply (1 million tokens)
    1000,                         // Token price in wei (1 token = 0.001 ether)
    5000 * 10 ** 18               // Fundraising goal (5000 ether)
  );

  await mutualFundToken.deployed();
  console.log("Fungible Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
