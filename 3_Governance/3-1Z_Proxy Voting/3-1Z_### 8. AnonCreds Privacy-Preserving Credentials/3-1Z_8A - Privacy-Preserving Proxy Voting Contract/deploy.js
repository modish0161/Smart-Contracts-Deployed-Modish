// scripts/deploy.js

async function main() {
    const PrivacyPreservingProxyVoting = await ethers.getContractFactory("PrivacyPreservingProxyVoting");
  
    const contract = await PrivacyPreservingProxyVoting.deploy();
  
    await contract.deployed();
  
    console.log("PrivacyPreservingProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  