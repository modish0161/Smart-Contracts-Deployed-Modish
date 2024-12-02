const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const LockUpPeriodContract = await hre.ethers.getContractFactory("LockUpPeriodContract");
  const lockUpPeriodContract = await LockUpPeriodContract.deploy();

  await lockUpPeriodContract.deployed();
  console.log("Lock-Up Period Contract deployed to:", lockUpPeriodContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
