async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiLayeredSettlement = await ethers.getContractFactory("MultiLayeredSettlement");
    const multiLayeredSettlement = await MultiLayeredSettlement.deploy("Multi-Layered Settlement Token", "MLST");
  
    console.log("MultiLayeredSettlement deployed to:", multiLayeredSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  