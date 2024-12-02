const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const BatchTransferHedgeFundToken = await hre.ethers.getContractFactory("BatchTransferHedgeFundToken");
  const token = await BatchTransferHedgeFundToken.deploy();

  await token.deployed();
  console.log("Batch Transfer Hedge Fund Token Contract deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
