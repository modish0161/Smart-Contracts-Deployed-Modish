const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const AdvancedAtomicSwap = await hre.ethers.getContractFactory("AdvancedAtomicSwap");
  const advancedAtomicSwap = await AdvancedAtomicSwap.deploy();

  await advancedAtomicSwap.deployed();

  console.log("AdvancedAtomicSwap deployed to:", advancedAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
