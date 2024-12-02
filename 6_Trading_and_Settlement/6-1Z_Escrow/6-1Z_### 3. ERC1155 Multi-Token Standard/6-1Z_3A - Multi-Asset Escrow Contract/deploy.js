async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const tokenContractAddress = "0xYourERC1155TokenAddress"; // Replace with actual ERC1155 token contract address
  
    const MultiAssetEscrow = await ethers.getContractFactory("MultiAssetEscrow");
    const escrow = await MultiAssetEscrow.deploy(tokenContractAddress);
    console.log("MultiAssetEscrow contract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  