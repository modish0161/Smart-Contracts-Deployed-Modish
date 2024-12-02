const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const PerformanceFeeContract = await hre.ethers.getContractFactory("PerformanceFeeContract");
  const performanceFeeContract = await PerformanceFeeContract.deploy(20, 1000); // 20% fee and 1000 threshold

  await performanceFeeContract.deployed();
  console.log("Performance Fee Contract deployed to:", performanceFeeContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
