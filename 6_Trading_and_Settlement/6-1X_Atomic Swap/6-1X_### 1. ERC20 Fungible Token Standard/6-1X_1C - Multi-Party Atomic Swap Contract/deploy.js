const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const MultiPartyAtomicSwap = await hre.ethers.getContractFactory("MultiPartyAtomicSwap");
  const multiPartyAtomicSwap = await MultiPartyAtomicSwap.deploy();

  await multiPartyAtomicSwap.deployed();

  console.log("MultiPartyAtomicSwap deployed to:", multiPartyAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
