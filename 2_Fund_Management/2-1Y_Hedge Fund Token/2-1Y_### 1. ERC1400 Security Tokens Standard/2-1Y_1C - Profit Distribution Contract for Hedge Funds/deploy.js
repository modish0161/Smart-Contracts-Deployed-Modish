const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const ProfitDistributionContract = await hre.ethers.getContractFactory("ProfitDistributionContract");
  const profitDistributionContract = await ProfitDistributionContract.deploy();

  await profitDistributionContract.deployed();
  console.log("Profit Distribution Contract deployed to:", profitDistributionContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
