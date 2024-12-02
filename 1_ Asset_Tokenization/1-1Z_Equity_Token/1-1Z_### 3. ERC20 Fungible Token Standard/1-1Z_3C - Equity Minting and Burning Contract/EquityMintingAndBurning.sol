// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Minting and Burning Contract
/// @notice This contract allows companies to mint new equity tokens when issuing more shares or burn tokens during buybacks or capital reduction events, ensuring the correct representation of outstanding shares.
contract EquityMintingAndBurning is ERC20, Ownable, ReentrancyGuard, Pausable {
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @notice Mints new tokens to the specified address
    /// @param to The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Burns tokens from the specified address
    /// @param from The address from which to burn the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /// @notice Allows the contract owner to pause all minting and burning operations
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause all minting and burning operations
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw any ETH mistakenly sent to this contract
    function emergencyWithdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens mistakenly sent to this contract
    /// @param token The address of the ERC20 token
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(owner(), amount);
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}

    /// @notice Override ERC20 _beforeTokenTransfer to enforce pausing
    /// @dev This function is called before any transfer of tokens. This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
