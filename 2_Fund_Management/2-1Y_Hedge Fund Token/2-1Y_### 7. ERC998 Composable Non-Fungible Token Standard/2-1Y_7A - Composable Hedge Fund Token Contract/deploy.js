const hre = require("hardhat");

async function main() {
  const ComposableHedgeFundToken = await hre.ethers.getContractFactory("ComposableHedgeFundToken");
  const tokenContract = await ComposableHedgeFundToken.deploy();
  await tokenContract.deployed();
  console.log("Composable Hedge Fund Token deployed to:", tokenContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
