const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const PerformanceFeeDistribution = await hre.ethers.getContractFactory("PerformanceFeeDistribution");
  const token = await PerformanceFeeDistribution.deploy("Hedge Fund Token", "HFT", 20); // 20% performance fee

  await token.deployed();
  console.log("Performance Fee Distribution Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
