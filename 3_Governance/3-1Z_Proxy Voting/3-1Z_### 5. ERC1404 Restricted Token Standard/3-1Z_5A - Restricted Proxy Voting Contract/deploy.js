// scripts/deploy.js

async function main() {
    const RestrictedProxyVoting = await ethers.getContractFactory("RestrictedProxyVoting");
  
    const restrictedProxyVotingContract = await RestrictedProxyVoting.deploy(
      "RestrictedToken",
      "RTK",
      1000000,
      []
    );
  
    await restrictedProxyVotingContract.deployed();
  
    console.log("RestrictedProxyVoting deployed to:", restrictedProxyVotingContract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  