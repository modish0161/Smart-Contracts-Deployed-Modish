async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const composableTokenAddress = "0xYourComposableTokenAddress"; // Replace with actual ERC998 composable token contract address
    const underlyingAssetTokenAddress = "0xYourUnderlyingAssetTokenAddress"; // Replace with actual ERC721 token contract address
  
    const BundledAssetEscrowContract = await ethers.getContractFactory("BundledAssetEscrowContract");
    const contract = await BundledAssetEscrowContract.deploy(composableTokenAddress, underlyingAssetTokenAddress);
  
    console.log("BundledAssetEscrowContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  