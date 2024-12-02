async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorAnonSwap = await ethers.getContractFactory("AccreditedInvestorAnonSwap");
    const accreditedInvestorAnonSwap = await AccreditedInvestorAnonSwap.deploy();
  
    console.log("AccreditedInvestorAnonSwap deployed to:", accreditedInvestorAnonSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  