async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorAtomicSwap = await ethers.getContractFactory("AccreditedInvestorAtomicSwap");
    const accreditedInvestorAtomicSwap = await AccreditedInvestorAtomicSwap.deploy();
  
    console.log("AccreditedInvestorAtomicSwap deployed to:", accreditedInvestorAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  