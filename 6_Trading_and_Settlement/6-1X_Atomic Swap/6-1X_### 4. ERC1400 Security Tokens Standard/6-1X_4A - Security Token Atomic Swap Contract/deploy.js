const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const SecurityTokenAtomicSwap = await hre.ethers.getContractFactory("SecurityTokenAtomicSwap");
  const securityTokenAtomicSwap = await SecurityTokenAtomicSwap.deploy();

  await securityTokenAtomicSwap.deployed();

  console.log("SecurityTokenAtomicSwap deployed to:", securityTokenAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
