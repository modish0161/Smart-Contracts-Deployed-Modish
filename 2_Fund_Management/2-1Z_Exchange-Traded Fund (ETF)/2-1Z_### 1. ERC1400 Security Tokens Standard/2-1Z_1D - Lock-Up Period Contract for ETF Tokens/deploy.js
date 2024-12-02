const hre = require("hardhat");

async function main() {
  const SecurityTokenAddress = "0x..."; // Replace with your deployed ERC1400 token address
  const LockUpPeriodETF = await hre.ethers.getContractFactory("LockUpPeriodETF");
  const lockUpPeriodContract = await LockUpPeriodETF.deploy(SecurityTokenAddress);
  await lockUpPeriodContract.deployed();
  console.log("Lock-Up Period Contract deployed to:", lockUpPeriodContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
