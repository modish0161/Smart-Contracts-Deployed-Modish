const hre = require("hardhat");

async function main() {
  const initialSupply = 1000000; // Set initial supply as needed
  const TaxWithholding = await hre.ethers.getContractFactory("TaxWithholding");
  const taxWithholding = await TaxWithholding.deploy(initialSupply);
  await taxWithholding.deployed();
  console.log("Tax Withholding Contract deployed to:", taxWithholding.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
