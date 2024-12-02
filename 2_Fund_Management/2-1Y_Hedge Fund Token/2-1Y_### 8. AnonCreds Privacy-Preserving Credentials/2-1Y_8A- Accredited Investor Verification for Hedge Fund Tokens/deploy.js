const hre = require("hardhat");

async function main() {
  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");
  const verificationContract = await AccreditedInvestorVerification.deploy();
  await verificationContract.deployed();
  console.log("Accredited Investor Verification deployed to:", verificationContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
