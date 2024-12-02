const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TimeLockedAtomicSwap = await hre.ethers.getContractFactory("TimeLockedAtomicSwap");
  const timeLockedAtomicSwap = await TimeLockedAtomicSwap.deploy();

  await timeLockedAtomicSwap.deployed();

  console.log("TimeLockedAtomicSwap deployed to:", timeLockedAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
