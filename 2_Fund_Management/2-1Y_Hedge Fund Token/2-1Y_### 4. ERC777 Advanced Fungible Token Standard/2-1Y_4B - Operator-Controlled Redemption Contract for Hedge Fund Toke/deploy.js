const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const defaultOperators = []; // Add any default operators if needed
  const operator = deployer.address; // Set deployer as the initial operator
  const AdvancedHedgeFundToken = await hre.ethers.getContractFactory("OperatorControlledRedemption");
  const token = await AdvancedHedgeFundToken.deploy("Hedge Fund Token", "HFT", defaultOperators, operator);

  await token.deployed();
  console.log("Operator-Controlled Redemption Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
