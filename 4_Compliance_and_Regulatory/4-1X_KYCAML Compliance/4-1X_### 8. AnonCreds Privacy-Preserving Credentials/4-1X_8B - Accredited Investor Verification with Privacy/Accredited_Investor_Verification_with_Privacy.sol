// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract AccreditedInvestorVerificationWithPrivacy is Ownable, AccessControl, Pausable, EIP712 {
    using ECDSA for bytes32;

    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant VERIFY_TYPEHASH = keccak256("Verify(address user,uint256 nonce)");
    string private constant SIGNING_DOMAIN = "KYCCompliance";
    string private constant SIGNATURE_VERSION = "1";

    mapping(address => bool) public accreditedInvestors;
    mapping(address => uint256) public nonces; // Keeps track of used nonces for each user

    event InvestorAccreditationStatusUpdated(address indexed user, bool isAccredited, uint256 timestamp);
    event TokenTransferRestricted(address indexed from, address indexed to, uint256 value);

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    /**
     * @notice Verifies the accreditation status of a user using privacy-preserving credentials.
     * @param user Address of the user to verify.
     * @param nonce Unique nonce for the verification.
     * @param signature Signature generated off-chain to verify accreditation.
     */
    function verifyInvestorAccreditation(address user, uint256 nonce, bytes memory signature) external whenNotPaused {
        require(nonces[user] < nonce, "Nonce already used");
        bytes32 structHash = keccak256(abi.encode(VERIFY_TYPEHASH, user, nonce));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(signature);
        require(hasRole(COMPLIANCE_OFFICER_ROLE, signer), "Invalid signer");

        nonces[user] = nonce;
        accreditedInvestors[user] = true;

        emit InvestorAccreditationStatusUpdated(user, true, block.timestamp);
    }

    /**
     * @notice Updates the accreditation status of an investor directly.
     * @param user Address of the investor to update.
     * @param status Accreditation status to set (true/false).
     */
    function setInvestorAccreditationStatus(address user, bool status) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        accreditedInvestors[user] = status;
        emit InvestorAccreditationStatusUpdated(user, status, block.timestamp);
    }

    /**
     * @notice Checks if a user is an accredited investor.
     * @param user Address of the user to check.
     * @return bool True if user is accredited, false otherwise.
     */
    function isInvestorAccredited(address user) public view returns (bool) {
        return accreditedInvestors[user];
    }

    /**
     * @notice Pauses the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the contract to receive ETH.
     */
    receive() external payable {}

    /**
     * @notice Withdraws all ETH in the contract to the owner.
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Allows owner to withdraw any ERC20 tokens held by this contract.
     * @param token Address of the ERC20 token to withdraw.
     */
    function withdrawERC20(address token) external onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice Destroys the contract and sends all remaining funds to the owner.
     */
    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for EIP712.
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Returns the current nonce for the user.
     * @param user Address of the user to check.
     * @return uint256 Nonce value for the user.
     */
    function getUserNonce(address user) external view returns (uint256) {
        return nonces[user];
    }
}
