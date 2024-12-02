async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BatchSettlementContract = await ethers.getContractFactory("BatchSettlementContract");
    const batchSettlementContract = await BatchSettlementContract.deploy("https://api.example.com/metadata/{id}.json");
  
    console.log("BatchSettlementContract deployed to:", batchSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  