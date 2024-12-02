async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AnonymousSettlementContract = await ethers.getContractFactory("AnonymousSettlementContract");
    const anonymousSettlementContract = await AnonymousSettlementContract.deploy();
  
    console.log("AnonymousSettlementContract deployed to:", anonymousSettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  