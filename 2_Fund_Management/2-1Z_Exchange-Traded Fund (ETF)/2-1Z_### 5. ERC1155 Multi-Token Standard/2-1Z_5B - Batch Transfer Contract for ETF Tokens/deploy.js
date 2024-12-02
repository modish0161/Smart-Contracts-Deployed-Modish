const hre = require("hardhat");

async function main() {
  const BatchTransferETFToken = await hre.ethers.getContractFactory("BatchTransferETFToken");
  const batchTransferETFToken = await BatchTransferETFToken.deploy("https://api.example.com/metadata/{id}");
  await batchTransferETFToken.deployed();
  console.log("Batch Transfer ETF Token Contract deployed to:", batchTransferETFToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
