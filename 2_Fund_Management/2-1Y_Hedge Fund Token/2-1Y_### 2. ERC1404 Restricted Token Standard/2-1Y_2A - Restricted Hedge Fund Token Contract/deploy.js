const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedHedgeFundToken = await hre.ethers.getContractFactory("RestrictedHedgeFundToken");
  const token = await RestrictedHedgeFundToken.deploy("HedgeFundToken", "HFT", 18);

  await token.deployed();
  console.log("Restricted Hedge Fund Token deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
