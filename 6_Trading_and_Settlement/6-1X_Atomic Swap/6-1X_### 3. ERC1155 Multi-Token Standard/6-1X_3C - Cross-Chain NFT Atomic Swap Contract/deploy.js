const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const CrossChainNFTAtomicSwap = await hre.ethers.getContractFactory("CrossChainNFTAtomicSwap");
  const crossChainNFTAtomicSwap = await CrossChainNFTAtomicSwap.deploy();

  await crossChainNFTAtomicSwap.deployed();

  console.log("CrossChainNFTAtomicSwap deployed to:", crossChainNFTAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
