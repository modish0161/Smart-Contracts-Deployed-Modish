async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const TimeLockedSettlementContract = await ethers.getContractFactory("TimeLockedSettlementContract");
    const timeLockedSettlementContract = await TimeLockedSettlementContract.deploy();
  
    console.log("TimeLockedSettlementContract deployed to:", timeLockedSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  