async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with your ERC1404 token address
  
    const RegulationCompliantSettlement = await ethers.getContractFactory("RegulationCompliantSettlement");
    const regulationCompliantSettlement = await RegulationCompliantSettlement.deploy(RestrictedTokenAddress);
  
    console.log("RegulationCompliantSettlement deployed to:", regulationCompliantSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  