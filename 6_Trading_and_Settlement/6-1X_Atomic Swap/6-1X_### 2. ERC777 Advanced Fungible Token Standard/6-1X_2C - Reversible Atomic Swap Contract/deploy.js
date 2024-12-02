const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ReversibleAtomicSwap = await hre.ethers.getContractFactory("ReversibleAtomicSwap");
  const reversibleAtomicSwap = await ReversibleAtomicSwap.deploy();

  await reversibleAtomicSwap.deployed();

  console.log("ReversibleAtomicSwap deployed to:", reversibleAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
