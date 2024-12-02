async function main() {
    const TransferRestrictions = await ethers.getContractFactory("TransferRestrictions");
    const transferRestrictions = await TransferRestrictions.deploy("Restricted Security Token", "RST", 18, 1000000);
    await transferRestrictions.deployed();
    console.log("TransferRestrictions deployed to:", transferRestrictions.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
