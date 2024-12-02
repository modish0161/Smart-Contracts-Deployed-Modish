async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const escrowTokenAddress = "0xYourERC20TokenAddress"; // Replace with the actual ERC20 token address
    const depositorAddress = "0xDepositorAddress"; // Replace with depositor address
    const beneficiaryAddress = "0xBeneficiaryAddress"; // Replace with beneficiary address
    const amount = ethers.utils.parseUnits("1000", 18); // Example: 1000 tokens with 18 decimals
    const releaseTime = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
  
    const TimeLockedEscrowContract = await ethers.getContractFactory("TimeLockedEscrowContract");
    const escrow = await TimeLockedEscrowContract.deploy(
      depositorAddress,
      beneficiaryAddress,
      escrowTokenAddress,
      amount,
      releaseTime
    );
  
    console.log("TimeLockedEscrowContract deployed to:", escrow.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  