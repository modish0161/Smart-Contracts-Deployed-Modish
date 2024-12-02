const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const RestrictedTokenAtomicSwap = await hre.ethers.getContractFactory("RestrictedTokenAtomicSwap");
  const restrictedTokenAtomicSwap = await RestrictedTokenAtomicSwap.deploy();

  await restrictedTokenAtomicSwap.deployed();

  console.log("RestrictedTokenAtomicSwap deployed to:", restrictedTokenAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
