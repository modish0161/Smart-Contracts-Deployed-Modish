async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const escrowTokenAddress = "0xYourERC777TokenAddress"; // Replace with actual ERC777 token address
    const depositorAddress = "0xDepositorAddress"; // Replace with depositor address
    const beneficiaryAddress = "0xBeneficiaryAddress"; // Replace with beneficiary address
    const amount = ethers.utils.parseUnits("1000", 18); // Example: 1000 tokens with 18 decimals
  
    const AdvancedEscrowContract = await ethers.getContractFactory("AdvancedEscrowContract");
    const escrow = await AdvancedEscrowContract.deploy(
      escrowTokenAddress,
      depositorAddress,
      beneficiaryAddress,
      amount
    );
  
    console.log("AdvancedEscrowContract deployed to:", escrow.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  