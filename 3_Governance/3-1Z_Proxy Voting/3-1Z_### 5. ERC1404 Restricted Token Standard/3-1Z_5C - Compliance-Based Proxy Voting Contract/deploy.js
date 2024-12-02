// scripts/deploy.js

async function main() {
    const ComplianceBasedProxyVoting = await ethers.getContractFactory("ComplianceBasedProxyVoting");
  
    const contract = await ComplianceBasedProxyVoting.deploy(
      "ComplianceToken",
      "CMT",
      1000000,
      []
    );
  
    await contract.deployed();
  
    console.log("ComplianceBasedProxyVoting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  