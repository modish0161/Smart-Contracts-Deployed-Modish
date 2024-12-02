const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const BatchAtomicSwap = await hre.ethers.getContractFactory("BatchAtomicSwap");
  const batchAtomicSwap = await BatchAtomicSwap.deploy();

  await batchAtomicSwap.deployed();

  console.log("BatchAtomicSwap deployed to:", batchAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
