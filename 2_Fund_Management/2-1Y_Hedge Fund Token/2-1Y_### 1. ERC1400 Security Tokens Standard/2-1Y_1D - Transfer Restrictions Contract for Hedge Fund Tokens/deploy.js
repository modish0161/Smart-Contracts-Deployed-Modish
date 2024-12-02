
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TransferRestrictionsContract = await hre.ethers.getContractFactory("TransferRestrictionsContract");
  const transferRestrictionsContract = await TransferRestrictionsContract.deploy();

  await transferRestrictionsContract.deployed();
  console.log("Transfer Restrictions Contract deployed to:", transferRestrictionsContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
