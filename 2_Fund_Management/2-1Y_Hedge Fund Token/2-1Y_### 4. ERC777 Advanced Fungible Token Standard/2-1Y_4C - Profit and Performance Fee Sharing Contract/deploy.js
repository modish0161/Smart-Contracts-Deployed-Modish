const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const defaultOperators = []; // Add any default operators if needed
  const performanceFeePercentage = 20; // Set initial performance fee percentage to 20%
  const ProfitAndPerformanceFeeSharing = await hre.ethers.getContractFactory("ProfitAndPerformanceFeeSharing");
  const token = await ProfitAndPerformanceFeeSharing.deploy("Hedge Fund Token", "HFT", defaultOperators, performanceFeePercentage);

  await token.deployed();
  console.log("Profit and Performance Fee Sharing Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
