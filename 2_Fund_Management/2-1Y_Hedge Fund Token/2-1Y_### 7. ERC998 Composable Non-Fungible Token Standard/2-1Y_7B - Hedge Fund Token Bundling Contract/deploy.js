const hre = require("hardhat");

async function main() {
  const HedgeFundTokenBundling = await hre.ethers.getContractFactory("HedgeFundTokenBundling");
  const tokenContract = await HedgeFundTokenBundling.deploy();
  await tokenContract.deployed();
  console.log("Hedge Fund Token Bundling deployed to:", tokenContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
