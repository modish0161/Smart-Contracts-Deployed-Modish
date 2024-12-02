// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract PrivacyPreservingKYCCompliance is Ownable, AccessControl, Pausable, EIP712 {
    using ECDSA for bytes32;

    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant VERIFY_TYPEHASH = keccak256("Verify(address user,uint256 nonce)");
    string private constant SIGNING_DOMAIN = "KYCCompliance";
    string private constant SIGNATURE_VERSION = "1";

    mapping(address => bool) public compliantUsers;
    mapping(address => uint256) public nonces; // Keeps track of used nonces for each user

    event UserComplianceStatusUpdated(address indexed user, bool isCompliant, uint256 timestamp);
    event TokenTransferRestricted(address indexed from, address indexed to, uint256 value);

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    /**
     * @notice Verifies the KYC/AML compliance status of a user using privacy-preserving credentials.
     * @param user Address of the user to verify.
     * @param nonce Unique nonce for the verification.
     * @param signature Signature generated off-chain to verify compliance.
     */
    function verifyUserCompliance(address user, uint256 nonce, bytes memory signature) external whenNotPaused {
        require(nonces[user] < nonce, "Nonce already used");
        bytes32 structHash = keccak256(abi.encode(VERIFY_TYPEHASH, user, nonce));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(signature);
        require(hasRole(COMPLIANCE_OFFICER_ROLE, signer), "Invalid signer");

        nonces[user] = nonce;
        compliantUsers[user] = true;

        emit UserComplianceStatusUpdated(user, true, block.timestamp);
    }

    /**
     * @notice Updates the compliance status of a user directly.
     * @param user Address of the user to update.
     * @param status Compliance status to set (true/false).
     */
    function setUserComplianceStatus(address user, bool status) external onlyRole(COMPLIANCE_OFFICER_ROLE) {
        compliantUsers[user] = status;
        emit UserComplianceStatusUpdated(user, status, block.timestamp);
    }

    /**
     * @notice Checks if a user is compliant.
     * @param user Address of the user to check.
     * @return bool True if user is compliant, false otherwise.
     */
    function isUserCompliant(address user) public view returns (bool) {
        return compliantUsers[user];
    }

    /**
     * @notice Allows a compliant user to transfer tokens.
     * @param token Address of the token contract.
     * @param to Address to transfer tokens to.
     * @param amount Amount of tokens to transfer.
     */
    function transferTokens(IERC20 token, address to, uint256 amount) external whenNotPaused {
        require(compliantUsers[msg.sender], "User not compliant");
        require(compliantUsers[to], "Recipient not compliant");

        token.transferFrom(msg.sender, to, amount);
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
    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
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
