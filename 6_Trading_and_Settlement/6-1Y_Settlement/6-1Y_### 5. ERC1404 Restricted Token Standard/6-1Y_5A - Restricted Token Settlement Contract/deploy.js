async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with your ERC1404 token address
  
    const RestrictedTokenSettlement = await ethers.getContractFactory("RestrictedTokenSettlement");
    const restrictedTokenSettlement = await RestrictedTokenSettlement.deploy(RestrictedTokenAddress);
  
    console.log("RestrictedTokenSettlement deployed to:", restrictedTokenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  