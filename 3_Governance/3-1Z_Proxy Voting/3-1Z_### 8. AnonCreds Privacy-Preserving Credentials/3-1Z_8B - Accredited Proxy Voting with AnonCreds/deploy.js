// scripts/deploy.js

async function main() {
    const AccreditedProxyVotingWithAnonCreds = await ethers.getContractFactory("AccreditedProxyVotingWithAnonCreds");
  
    const contract = await AccreditedProxyVotingWithAnonCreds.deploy();
  
    await contract.deployed();
  
    console.log("AccreditedProxyVotingWithAnonCreds deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  