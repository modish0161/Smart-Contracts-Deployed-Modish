async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RealTimeSettlementContract = await ethers.getContractFactory("RealTimeSettlementContract");
    const realTimeSettlementContract = await RealTimeSettlementContract.deploy();
  
    console.log("RealTimeSettlementContract deployed to:", realTimeSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  