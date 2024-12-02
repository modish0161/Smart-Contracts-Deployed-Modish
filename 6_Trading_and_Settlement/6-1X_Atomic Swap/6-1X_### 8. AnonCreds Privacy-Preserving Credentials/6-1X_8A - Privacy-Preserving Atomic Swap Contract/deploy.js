async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingAtomicSwap = await ethers.getContractFactory("PrivacyPreservingAtomicSwap");
    const privacyPreservingAtomicSwap = await PrivacyPreservingAtomicSwap.deploy();
  
    console.log("PrivacyPreservingAtomicSwap deployed to:", privacyPreservingAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  