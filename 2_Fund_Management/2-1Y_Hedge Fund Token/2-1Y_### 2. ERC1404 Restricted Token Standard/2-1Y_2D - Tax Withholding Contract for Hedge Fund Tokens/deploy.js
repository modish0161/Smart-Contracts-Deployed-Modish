const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TaxWithholding = await hre.ethers.getContractFactory("TaxWithholding");
  const token = await TaxWithholding.deploy("HedgeFundToken", "HFT", 18, 200); // 2% tax rate

  await token.deployed();
  console.log("Tax Withholding Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
