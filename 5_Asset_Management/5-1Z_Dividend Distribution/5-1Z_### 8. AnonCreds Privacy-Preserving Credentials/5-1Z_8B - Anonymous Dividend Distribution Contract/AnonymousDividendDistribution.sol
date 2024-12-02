// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IAnonCreds {
    function verifyCredential(address user, bytes32 credentialHash) external view returns (bool);
}

contract AnonymousDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public dividendToken;  // ERC20 Token used for distributing dividends
    IAnonCreds public anonCreds;  // AnonCreds contract for privacy-preserving credential verification
    uint256 public totalDividends; // Total dividends available for distribution
    mapping(bytes32 => uint256) public userDividends; // Track user dividends by credential hash
    mapping(bytes32 => uint256) public claimedDividends; // Track claimed dividends by credential hash

    event DividendsDistributed(uint256 amount);
    event DividendsClaimed(bytes32 indexed credentialHash, uint256 amount);

    constructor(address _dividendToken, address _anonCreds) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_anonCreds != address(0), "Invalid AnonCreds contract address");

        dividendToken = IERC20(_dividendToken);
        anonCreds = IAnonCreds(_anonCreds);
    }

    // Distribute dividends to users with verified credentials
    function distributeDividends(bytes32[] calldata credentialHashes, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        uint256 totalCredentialHashes = credentialHashes.length;
        uint256 dividendPerCredential = amount.div(totalCredentialHashes);

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        for (uint256 i = 0; i < totalCredentialHashes; i++) {
            userDividends[credentialHashes[i]] = userDividends[credentialHashes[i]].add(dividendPerCredential);
        }

        emit DividendsDistributed(amount);
    }

    // Claim dividends using a valid credential
    function claimDividends(bytes32 credentialHash) external nonReentrant {
        require(anonCreds.verifyCredential(msg.sender, credentialHash), "Invalid or unverified credential");

        uint256 unclaimedDividends = getUnclaimedDividends(credentialHash);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[credentialHash] = claimedDividends[credentialHash].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(credentialHash, unclaimedDividends);
    }

    // Get unclaimed dividends for a given credential hash
    function getUnclaimedDividends(bytes32 credentialHash) public view returns (uint256) {
        uint256 entitledDividends = userDividends[credentialHash];
        uint256 claimedAmount = claimedDividends[credentialHash];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Withdraw remaining dividends to the owner
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
