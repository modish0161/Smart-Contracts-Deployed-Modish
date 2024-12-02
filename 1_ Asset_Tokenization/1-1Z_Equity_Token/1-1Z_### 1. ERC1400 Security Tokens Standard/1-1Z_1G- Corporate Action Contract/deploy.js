const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const CorporateActionContract = await ethers.getContractFactory("CorporateActionContract");
  const corporateActionContract = await CorporateActionContract.deploy("YOUR_ERC1400_TOKEN_ADDRESS");
  await corporateActionContract.deployed();

  console.log("Corporate Action Contract deployed to:", corporateActionContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
