async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const restrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with actual ERC1404 token contract address
    const complianceAuthorityAddress = "0xYourComplianceAuthorityAddress"; // Replace with actual compliance authority address
  
    const RegulationCompliantEscrowContract = await ethers.getContractFactory("RegulationCompliantEscrowContract");
    const escrow = await RegulationCompliantEscrowContract.deploy(restrictedTokenAddress, complianceAuthorityAddress);
    console.log("RegulationCompliantEscrowContract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  