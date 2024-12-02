// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AccreditedInvestorVerification is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // Struct to store investor accreditation status
    struct Investor {
        bool isAccredited;
        uint256 expiry;
    }

    // Mapping from investor address to their accreditation status
    mapping(address => Investor) public investors;

    // Event to notify investor accreditation status change
    event InvestorAccredited(address indexed investor, uint256 expiry);
    event InvestorRemoved(address indexed investor);

    // Address of the mutual fund token contract
    address public mutualFundToken;

    // Verification authority public key for signature verification
    address public verificationAuthority;

    // Constructor to set initial mutual fund token address and verification authority
    constructor(address _mutualFundToken, address _verificationAuthority) {
        require(_mutualFundToken != address(0), "Invalid mutual fund token address");
        require(_verificationAuthority != address(0), "Invalid verification authority address");
        mutualFundToken = _mutualFundToken;
        verificationAuthority = _verificationAuthority;
    }

    // Modifier to check if the caller is an accredited investor
    modifier onlyAccreditedInvestor() {
        require(investors[msg.sender].isAccredited, "Not an accredited investor");
        require(investors[msg.sender].expiry > block.timestamp, "Accreditation expired");
        _;
    }

    // Function to set the mutual fund token address
    function setMutualFundToken(address _mutualFundToken) external onlyOwner {
        require(_mutualFundToken != address(0), "Invalid mutual fund token address");
        mutualFundToken = _mutualFundToken;
    }

    // Function to set the verification authority
    function setVerificationAuthority(address _verificationAuthority) external onlyOwner {
        require(_verificationAuthority != address(0), "Invalid verification authority address");
        verificationAuthority = _verificationAuthority;
    }

    // Function to verify and add an accredited investor
    function verifyInvestor(
        address _investor,
        uint256 _expiry,
        bytes calldata _signature
    ) external nonReentrant {
        require(_investor != address(0), "Invalid investor address");
        require(_expiry > block.timestamp, "Expiry must be in the future");

        // Construct the message for verification
        bytes32 message = keccak256(abi.encodePacked(_investor, _expiry));
        bytes32 messageHash = message.toEthSignedMessageHash();

        // Verify the signature
        require(
            messageHash.recover(_signature) == verificationAuthority,
            "Invalid signature"
        );

        // Update the investor accreditation status
        investors[_investor] = Investor({
            isAccredited: true,
            expiry: _expiry
        });

        emit InvestorAccredited(_investor, _expiry);
    }

    // Function to remove an accredited investor
    function removeInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        delete investors[_investor];
        emit InvestorRemoved(_investor);
    }

    // Function to allow only accredited investors to invest in the mutual fund
    function invest(uint256 amount) external onlyAccreditedInvestor nonReentrant {
        require(amount > 0, "Investment amount must be greater than zero");
        IERC20(mutualFundToken).transferFrom(msg.sender, address(this), amount);
        // Additional logic for investing can be implemented here
    }

    // Function to withdraw investment
    function withdraw(uint256 amount) external onlyAccreditedInvestor nonReentrant {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        IERC20(mutualFundToken).transfer(msg.sender, amount);
        // Additional logic for withdrawing can be implemented here
    }
}
