// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MintingBurningETFToken is ERC20, Ownable, Pausable, ERC20Burnable {
    
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    constructor() ERC20("Fungible ETF Token", "FET") {
        // Initial minting can be done here if necessary
    }

    // Function to mint new tokens, only callable by the owner
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // Function to burn tokens, allowing users to redeem their tokens
    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    // Function to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override _beforeTokenTransfer to implement pausable functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
