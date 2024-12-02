const hre = require("hardhat");

async function main() {
  const defaultOperators = []; // Add default operators if necessary
  const OperatorControlledRedemption = await hre.ethers.getContractFactory("OperatorControlledRedemption");
  const operatorControlledRedemption = await OperatorControlledRedemption.deploy("ETF Token", "ETFT", defaultOperators);
  await operatorControlledRedemption.deployed();
  console.log("Operator Controlled Redemption Contract deployed to:", operatorControlledRedemption.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
