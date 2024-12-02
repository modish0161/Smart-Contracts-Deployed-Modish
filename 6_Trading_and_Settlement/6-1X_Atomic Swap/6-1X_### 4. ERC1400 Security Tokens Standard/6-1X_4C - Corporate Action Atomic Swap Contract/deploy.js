const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const CorporateActionAtomicSwap = await hre.ethers.getContractFactory("CorporateActionAtomicSwap");
  const corporateActionAtomicSwap = await CorporateActionAtomicSwap.deploy();

  await corporateActionAtomicSwap.deployed();

  console.log("CorporateActionAtomicSwap deployed to:", corporateActionAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
