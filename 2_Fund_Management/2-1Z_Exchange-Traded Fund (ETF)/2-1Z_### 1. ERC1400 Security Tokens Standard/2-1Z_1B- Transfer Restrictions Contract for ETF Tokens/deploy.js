const hre = require("hardhat");

async function main() {
  const TransferRestrictionsETF = await hre.ethers.getContractFactory("TransferRestrictionsETF");
  const transferRestrictionsContract = await TransferRestrictionsETF.deploy();
  await transferRestrictionsContract.deployed();
  console.log("Transfer Restrictions Contract deployed to:", transferRestrictionsContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
