async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BasicSettlementContract = await ethers.getContractFactory("BasicSettlementContract");
    const basicSettlementContract = await BasicSettlementContract.deploy();
  
    console.log("BasicSettlementContract deployed to:", basicSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  