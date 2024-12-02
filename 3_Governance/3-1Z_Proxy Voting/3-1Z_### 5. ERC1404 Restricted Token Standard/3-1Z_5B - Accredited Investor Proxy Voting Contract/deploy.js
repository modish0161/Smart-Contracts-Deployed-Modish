// scripts/deploy.js

async function main() {
    const AccreditedInvestorProxyVoting = await ethers.getContractFactory("AccreditedInvestorProxyVoting");
  
    const contract = await AccreditedInvestorProxyVoting.deploy(
      "AccreditedToken",
      "AKT",
      1000000,
      []
    );
  
    await contract.deployed();
  
    console.log("AccreditedInvestorProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  