const hre = require("hardhat");

async function main() {
  const defaultOperators = []; // Add default operators if necessary
  const AdvancedETFToken = await hre.ethers.getContractFactory("AdvancedETFToken");
  const advancedETFToken = await AdvancedETFToken.deploy("Advanced ETF Token", "AET", defaultOperators);
  await advancedETFToken.deployed();
  console.log("Advanced ETF Token deployed to:", advancedETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
