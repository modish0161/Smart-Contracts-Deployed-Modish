async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const escrowTokenAddress = "0xYourERC20TokenAddress"; // Replace with the actual ERC20 token address
    const BasicEscrowContract = await ethers.getContractFactory("BasicEscrowContract");
    const basicEscrowContract = await BasicEscrowContract.deploy(escrowTokenAddress);
  
    console.log("BasicEscrowContract deployed to:", basicEscrowContract.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  