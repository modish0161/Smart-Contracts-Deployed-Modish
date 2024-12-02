// scripts/deploy.js

async function main() {
    const RegulatedProxyVotingWithCompliance = await ethers.getContractFactory("RegulatedProxyVotingWithCompliance");
  
    const regulatedProxyVotingContract = await RegulatedProxyVotingWithCompliance.deploy(
      "RegulatedToken",
      "RTK",
      1000000,
      []
    );
  
    await regulatedProxyVotingContract.deployed();
  
    console.log("RegulatedProxyVotingWithCompliance deployed to:", regulatedProxyVotingContract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  