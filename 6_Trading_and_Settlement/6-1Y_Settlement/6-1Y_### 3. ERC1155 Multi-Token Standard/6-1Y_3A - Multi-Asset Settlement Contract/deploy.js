async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiAssetSettlementContract = await ethers.getContractFactory("MultiAssetSettlementContract");
    const multiAssetSettlementContract = await MultiAssetSettlementContract.deploy("https://api.example.com/metadata/{id}.json");
  
    console.log("MultiAssetSettlementContract deployed to:", multiAssetSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  