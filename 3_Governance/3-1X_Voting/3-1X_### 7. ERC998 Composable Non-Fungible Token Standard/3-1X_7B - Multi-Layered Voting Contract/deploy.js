// scripts/deploy.js

async function main() {
    // Get the contract factory
    const MultiLayeredVotingContract = await ethers.getContractFactory("MultiLayeredVotingContract");
  
    // Replace this with the deployed ERC998 contract address
    const erc998TokenAddress = "0xYourERC998TokenAddressHere";
  
    // Deploy the contract with the ERC998 token address
    const multiLayeredVoting = await MultiLayeredVotingContract.deploy(erc998TokenAddress);
  
    await multiLayeredVoting.deployed();
  
    console.log("MultiLayeredVotingContract deployed to:", multiLayeredVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  