const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ComplianceDrivenAtomicSwap = await hre.ethers.getContractFactory("ComplianceDrivenAtomicSwap");
  const complianceDrivenAtomicSwap = await ComplianceDrivenAtomicSwap.deploy();

  await complianceDrivenAtomicSwap.deployed();

  console.log("ComplianceDrivenAtomicSwap deployed to:", complianceDrivenAtomicSwap.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
