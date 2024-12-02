async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with your ERC1404 token address
  
    const AccreditedInvestorSettlement = await ethers.getContractFactory("AccreditedInvestorSettlement");
    const accreditedInvestorSettlement = await AccreditedInvestorSettlement.deploy(RestrictedTokenAddress);
  
    console.log("AccreditedInvestorSettlement deployed to:", accreditedInvestorSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  