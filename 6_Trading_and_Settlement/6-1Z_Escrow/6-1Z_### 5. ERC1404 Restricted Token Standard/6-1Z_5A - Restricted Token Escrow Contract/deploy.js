async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const restrictedTokenAddress = "0xYourRestrictedTokenAddress"; // Replace with actual ERC1404 token contract address
  
    const RestrictedTokenEscrowContract = await ethers.getContractFactory("RestrictedTokenEscrowContract");
    const escrow = await RestrictedTokenEscrowContract.deploy(restrictedTokenAddress);
    console.log("RestrictedTokenEscrowContract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  