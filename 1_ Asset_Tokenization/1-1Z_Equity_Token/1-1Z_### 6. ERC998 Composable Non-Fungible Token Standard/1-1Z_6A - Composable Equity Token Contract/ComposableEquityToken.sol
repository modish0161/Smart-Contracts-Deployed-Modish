// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ComposableEquityToken is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    struct EquityBundle {
        uint256[] tokenIds;
        address[] equityTokens;
        uint256[] amounts;
    }

    mapping(uint256 => EquityBundle) private _bundles;
    uint256 private _nextTokenId;

    event BundleCreated(uint256 indexed bundleId, address indexed owner);
    event EquityAdded(uint256 indexed bundleId, address equityToken, uint256 amount);
    event EquityRemoved(uint256 indexed bundleId, address equityToken, uint256 amount);

    constructor() ERC721("Composable Equity Token", "CET") {}

    function createBundle() external whenNotPaused nonReentrant returns (uint256) {
        uint256 bundleId = _nextTokenId++;
        _mint(msg.sender, bundleId);

        emit BundleCreated(bundleId, msg.sender);
        return bundleId;
    }

    function addEquityToBundle(uint256 bundleId, address equityToken, uint256 amount) external whenNotPaused nonReentrant {
        require(ownerOf(bundleId) == msg.sender, "Not the owner of the bundle");
        require(IERC20(equityToken).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        _bundles[bundleId].equityTokens.push(equityToken);
        _bundles[bundleId].amounts.push(amount);

        emit EquityAdded(bundleId, equityToken, amount);
    }

    function removeEquityFromBundle(uint256 bundleId, address equityToken, uint256 amount) external whenNotPaused nonReentrant {
        require(ownerOf(bundleId) == msg.sender, "Not the owner of the bundle");

        EquityBundle storage bundle = _bundles[bundleId];
        bool found = false;
        for (uint256 i = 0; i < bundle.equityTokens.length; i++) {
            if (bundle.equityTokens[i] == equityToken && bundle.amounts[i] >= amount) {
                bundle.amounts[i] -= amount;
                if (bundle.amounts[i] == 0) {
                    _removeEquity(bundle, i);
                }
                found = true;
                break;
            }
        }
        require(found, "Equity not found or insufficient amount");

        require(IERC20(equityToken).transfer(msg.sender, amount), "Transfer failed");
        emit EquityRemoved(bundleId, equityToken, amount);
    }

    function getBundleDetails(uint256 bundleId) external view returns (address[] memory, uint256[] memory) {
        require(_exists(bundleId), "Bundle does not exist");
        return (_bundles[bundleId].equityTokens, _bundles[bundleId].amounts);
    }

    function _removeEquity(EquityBundle storage bundle, uint256 index) private {
        require(index < bundle.equityTokens.length, "Index out of bounds");

        for (uint256 i = index; i < bundle.equityTokens.length - 1; i++) {
            bundle.equityTokens[i] = bundle.equityTokens[i + 1];
            bundle.amounts[i] = bundle.amounts[i + 1];
        }

        bundle.equityTokens.pop();
        bundle.amounts.pop();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
