const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MultiAssetAtomicSwap = await hre.ethers.getContractFactory("MultiAssetAtomicSwap");
  const multiAssetAtomicSwap = await MultiAssetAtomicSwap.deploy();

  await multiAssetAtomicSwap.deployed();

  console.log("MultiAssetAtomicSwap deployed to:", multiAssetAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
