const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const OperatorControlledAtomicSwap = await hre.ethers.getContractFactory("OperatorControlledAtomicSwap");
  const operatorControlledAtomicSwap = await OperatorControlledAtomicSwap.deploy();

  await operatorControlledAtomicSwap.deployed();

  console.log("OperatorControlledAtomicSwap deployed to:", operatorControlledAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
