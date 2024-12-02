// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FungibleETFToken is ERC20, Ownable, Pausable, ERC20Burnable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18; // 1 million tokens

    // Events
    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    constructor() ERC20("Fungible ETF Token", "FET") {
        _mint(msg.sender, INITIAL_SUPPLY); // Mint initial supply to the contract owner
    }

    // Mint new tokens (only owner)
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }

    // Pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transfer functions to incorporate pausable functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Override burn function to emit an event
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokenBurned(msg.sender, amount);
    }
}
