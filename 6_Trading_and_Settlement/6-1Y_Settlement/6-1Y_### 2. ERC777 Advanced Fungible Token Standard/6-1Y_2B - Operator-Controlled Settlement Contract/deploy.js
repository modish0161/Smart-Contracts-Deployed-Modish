async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const OperatorControlledSettlementContract = await ethers.getContractFactory("OperatorControlledSettlementContract");
    const operatorControlledSettlementContract = await OperatorControlledSettlementContract.deploy();
  
    console.log("OperatorControlledSettlementContract deployed to:", operatorControlledSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  