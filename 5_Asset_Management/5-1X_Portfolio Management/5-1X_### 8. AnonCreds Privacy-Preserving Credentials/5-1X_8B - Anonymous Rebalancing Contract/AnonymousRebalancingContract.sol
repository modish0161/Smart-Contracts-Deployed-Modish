// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AnonymousRebalancingContract is Ownable, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    // Struct for storing investor portfolio details
    struct Portfolio {
        uint256 totalValue;
        bool isActive;
    }

    // Mapping of portfolio ID to portfolio details
    mapping(uint256 => Portfolio) public portfolios;

    // Merkle root for verifying anonymous credentials
    bytes32 public merkleRoot;

    // Events
    event PortfolioCreated(uint256 indexed portfolioId, uint256 initialValue);
    event PortfolioRebalanced(uint256 indexed portfolioId, uint256 newTotalValue, address indexed initiator);
    event PortfolioDeactivated(uint256 indexed portfolioId, address indexed initiator);

    // Constructor to set the initial Merkle root
    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    // Modifier to ensure the portfolio exists and is active
    modifier portfolioExists(uint256 portfolioId) {
        require(portfolios[portfolioId].isActive, "Portfolio does not exist or is inactive");
        _;
    }

    // Function to create a new portfolio with anonymous credentials
    function createPortfolio(
        uint256 portfolioId,
        uint256 initialValue,
        bytes32[] calldata proof
    ) external whenNotPaused nonReentrant {
        require(!portfolios[portfolioId].isActive, "Portfolio already exists");
        require(_verify(_leaf(msg.sender), proof), "Invalid anonymous credentials");

        portfolios[portfolioId] = Portfolio({
            totalValue: initialValue,
            isActive: true
        });

        emit PortfolioCreated(portfolioId, initialValue);
    }

    // Function to rebalance the portfolio
    function rebalancePortfolio(uint256 portfolioId, uint256 newTotalValue) external portfolioExists(portfolioId) nonReentrant whenNotPaused {
        require(newTotalValue > 0, "New total value must be greater than zero");

        portfolios[portfolioId].totalValue = newTotalValue;

        emit PortfolioRebalanced(portfolioId, newTotalValue, msg.sender);
    }

    // Function to deactivate a portfolio
    function deactivatePortfolio(uint256 portfolioId) external portfolioExists(portfolioId) nonReentrant whenNotPaused {
        portfolios[portfolioId].isActive = false;
        emit PortfolioDeactivated(portfolioId, msg.sender);
    }

    // Verify the Merkle proof for anonymous credentials
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // Generate the leaf node for Merkle tree verification
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    // Update the Merkle root for anonymous credentials (Admin only)
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // Pause and unpause the contract
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
