async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const BatchTransferContract = await ethers.getContractFactory("BatchTransferContract");
    const batchTransferContract = await BatchTransferContract.deploy("https://api.example.com/metadata/");

    console.log("BatchTransferContract deployed to:", batchTransferContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
