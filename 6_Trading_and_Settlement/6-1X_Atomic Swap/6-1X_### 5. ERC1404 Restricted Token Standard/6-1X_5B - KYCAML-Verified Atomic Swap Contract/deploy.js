async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const KYCAMLVerifiedAtomicSwap = await ethers.getContractFactory("KYCAMLVerifiedAtomicSwap");
    const kycAMLVerifiedAtomicSwap = await KYCAMLVerifiedAtomicSwap.deploy();
  
    console.log("KYCAMLVerifiedAtomicSwap deployed to:", kycAMLVerifiedAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  