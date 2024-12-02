async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const restrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with actual ERC1404 token contract address
  
    const AccreditedInvestorEscrowContract = await ethers.getContractFactory("AccreditedInvestorEscrowContract");
    const escrow = await AccreditedInvestorEscrowContract.deploy(restrictedTokenAddress);
    console.log("AccreditedInvestorEscrowContract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  