// scripts/deploy.js

async function main() {
    const CorporateGovernanceProxyVoting = await ethers.getContractFactory("CorporateGovernanceProxyVoting");
  
    const corporateGovernanceProxyVoting = await CorporateGovernanceProxyVoting.deploy(
      "CorporateGovernanceToken",
      "CGT",
      1000000,
      []
    );
  
    await corporateGovernanceProxyVoting.deployed();
  
    console.log("CorporateGovernanceProxyVoting deployed to:", corporateGovernanceProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  