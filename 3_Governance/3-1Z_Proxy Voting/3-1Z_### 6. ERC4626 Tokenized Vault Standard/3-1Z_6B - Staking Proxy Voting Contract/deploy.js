// scripts/deploy.js

async function main() {
    const StakingProxyVoting = await ethers.getContractFactory("StakingProxyVoting");
  
    const contract = await StakingProxyVoting.deploy("VaultToken", "VLT", "0xYourAssetAddressHere");
  
    await contract.deployed();
  
    console.log("StakingProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  