async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiPartySettlementContract = await ethers.getContractFactory("MultiPartySettlementContract");
    const multiPartySettlementContract = await MultiPartySettlementContract.deploy();
  
    console.log("MultiPartySettlementContract deployed to:", multiPartySettlementContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  