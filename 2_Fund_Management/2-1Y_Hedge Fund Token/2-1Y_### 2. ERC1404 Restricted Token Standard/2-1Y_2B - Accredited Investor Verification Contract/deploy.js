const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");
  const token = await AccreditedInvestorVerification.deploy("HedgeFundToken", "HFT", 18);

  await token.deployed();
  console.log("Accredited Investor Verification Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
