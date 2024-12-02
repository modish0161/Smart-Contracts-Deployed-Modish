async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AdvancedSettlementContract = await ethers.getContractFactory("AdvancedSettlementContract");
    const advancedSettlementContract = await AdvancedSettlementContract.deploy();
  
    console.log("AdvancedSettlementContract deployed to:", advancedSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  