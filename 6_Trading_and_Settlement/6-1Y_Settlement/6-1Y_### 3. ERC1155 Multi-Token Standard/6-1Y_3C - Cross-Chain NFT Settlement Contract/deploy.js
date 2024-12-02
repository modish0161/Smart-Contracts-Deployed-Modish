async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BridgeAddress = "0xYourBridgeAddress"; // Replace with your bridge contract address
    const uri = "https://api.example.com/metadata/{id}.json"; // Replace with your metadata URI
  
    const CrossChainNFTSettlement = await ethers.getContractFactory("CrossChainNFTSettlement");
    const crossChainNFTSettlement = await CrossChainNFTSettlement.deploy(uri, BridgeAddress);
  
    console.log("CrossChainNFTSettlement deployed to:", crossChainNFTSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  