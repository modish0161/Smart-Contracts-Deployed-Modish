async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const tokenContractAddress = "0xYourERC1155TokenAddress"; // Replace with actual ERC1155 token contract address
  
    const NFTEscrow = await ethers.getContractFactory("NFTEscrow");
    const escrow = await NFTEscrow.deploy(tokenContractAddress);
    console.log("NFTEscrow contract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  