const hre = require("hardhat");

async function main() {
  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");
  const contract = await AccreditedInvestorVerification.deploy();
  await contract.deployed();
  console.log("Accredited Investor Verification Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
