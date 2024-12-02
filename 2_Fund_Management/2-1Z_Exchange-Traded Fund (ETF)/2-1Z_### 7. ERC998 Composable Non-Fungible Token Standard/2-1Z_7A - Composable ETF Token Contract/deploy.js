const hre = require("hardhat");

async function main() {
  const ComposableETFToken = await hre.ethers.getContractFactory("ComposableETFToken");
  const composableETFToken = await ComposableETFToken.deploy();
  await composableETFToken.deployed();
  console.log("Composable ETF Token Contract deployed to:", composableETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
