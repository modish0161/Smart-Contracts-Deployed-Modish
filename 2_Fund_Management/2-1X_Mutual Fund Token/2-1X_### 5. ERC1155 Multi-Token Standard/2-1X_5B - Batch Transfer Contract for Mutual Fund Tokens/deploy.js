const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const uri = "https://example.com/api/metadata/{id}.json"; // Set your metadata URI

  const BatchTransferMutualFund = await hre.ethers.getContractFactory("BatchTransferMutualFund");
  const mutualFundToken = await BatchTransferMutualFund.deploy(uri);

  await mutualFundToken.deployed();
  console.log("Batch Transfer Mutual Fund Token deployed to:", mutualFundToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
