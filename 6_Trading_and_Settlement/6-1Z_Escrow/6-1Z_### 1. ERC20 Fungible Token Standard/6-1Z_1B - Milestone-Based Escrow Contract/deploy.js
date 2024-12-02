async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const escrowTokenAddress = "0xYourERC20TokenAddress"; // Replace with the actual ERC20 token address
    const depositorAddress = "0xDepositorAddress"; // Replace with depositor address
    const beneficiaryAddress = "0xBeneficiaryAddress"; // Replace with beneficiary address
  
    const MilestoneBasedEscrowContract = await ethers.getContractFactory("MilestoneBasedEscrowContract");
    const milestoneEscrow = await MilestoneBasedEscrowContract.deploy(depositorAddress, beneficiaryAddress, escrowTokenAddress);
  
    console.log("MilestoneBasedEscrowContract deployed to:", milestoneEscrow.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  