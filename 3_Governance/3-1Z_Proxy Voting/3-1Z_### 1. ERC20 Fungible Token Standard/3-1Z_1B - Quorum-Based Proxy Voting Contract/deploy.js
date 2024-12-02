// scripts/deploy.js

async function main() {
    // Get the contract factory
    const QuorumBasedProxyVoting = await ethers.getContractFactory("QuorumBasedProxyVoting");
  
    // Deployment parameters
    const name = "Quorum Based Voting Token";
    const symbol = "QBVT";
    const initialQuorum = 1000; // Example quorum value
  
    // Deploy the contract with necessary parameters
    const quorumBasedProxyVoting = await QuorumBasedProxyVoting.deploy(name, symbol, initialQuorum);
  
    await quorumBasedProxyVoting.deployed();
  
    console.log("QuorumBasedProxyVoting deployed to:", quorumBasedProxyVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  