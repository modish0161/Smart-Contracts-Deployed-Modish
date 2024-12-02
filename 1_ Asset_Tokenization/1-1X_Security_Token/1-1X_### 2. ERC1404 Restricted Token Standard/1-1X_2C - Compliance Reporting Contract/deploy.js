async function main() {
    const ComplianceReportingContract = await ethers.getContractFactory("ComplianceReportingContract");
    const complianceReportingContract = await ComplianceReportingContract.deploy("Compliance Reporting Token", "CRT", 18, 1000000);
    await complianceReportingContract.deployed();
    console.log("ComplianceReportingContract deployed to:", complianceReportingContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
