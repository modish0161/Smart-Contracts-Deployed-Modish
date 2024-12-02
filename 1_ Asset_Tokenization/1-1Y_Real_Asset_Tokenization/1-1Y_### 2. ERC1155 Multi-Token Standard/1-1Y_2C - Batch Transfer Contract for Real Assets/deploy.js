// deployment script using Hardhat

const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const uri = "https://example.com/metadata/{id}.json"; // replace with your metadata URI
  const BatchTransferRealAssets = await ethers.getContractFactory("BatchTransferRealAssets");
  const batchTransferRealAssets = await BatchTransferRealAssets.deploy(uri);

  console.log("Contract address:", batchTransferRealAssets.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
