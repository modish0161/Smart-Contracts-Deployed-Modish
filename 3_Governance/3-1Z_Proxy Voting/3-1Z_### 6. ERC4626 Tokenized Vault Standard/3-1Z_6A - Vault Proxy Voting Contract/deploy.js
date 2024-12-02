// scripts/deploy.js

async function main() {
    const VaultProxyVoting = await ethers.getContractFactory("VaultProxyVoting");
  
    const contract = await VaultProxyVoting.deploy("VaultToken", "VLT", "0xYourAssetAddressHere");
  
    await contract.deployed();
  
    console.log("VaultProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  