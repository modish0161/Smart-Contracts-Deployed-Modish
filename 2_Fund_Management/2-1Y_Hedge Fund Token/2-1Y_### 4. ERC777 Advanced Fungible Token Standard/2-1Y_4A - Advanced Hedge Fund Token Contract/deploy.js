const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const defaultOperators = []; // Add any default operators if needed
  const AdvancedHedgeFundToken = await hre.ethers.getContractFactory("AdvancedHedgeFundToken");
  const token = await AdvancedHedgeFundToken.deploy("Hedge Fund Token", "HFT", defaultOperators);

  await token.deployed();
  console.log("Advanced Hedge Fund Token Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
