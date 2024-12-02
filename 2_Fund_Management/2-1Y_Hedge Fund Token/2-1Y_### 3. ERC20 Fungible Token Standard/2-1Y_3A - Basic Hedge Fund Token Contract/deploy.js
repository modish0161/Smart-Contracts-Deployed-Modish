const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const HedgeFundToken = await hre.ethers.getContractFactory("BasicHedgeFundToken");
  const token = await HedgeFundToken.deploy("Hedge Fund Token", "HFT", 1000000); // 1 million max supply

  await token.deployed();
  console.log("Basic Hedge Fund Token deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
