// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleMerchNFT
 * @dev Lightweight NFT marketplace for physical goods
 */
contract GoodieMerchNFT is ERC721, Ownable {
    
    uint256 private _tokenIds;
    uint256 public platformFee = 250; // 2.5%
    
    struct Item {
        uint256 price;
        address seller;
        bool forSale;
    }
    
    mapping(uint256 => Item) public items;
    mapping(uint256 => string) private _tokenURIs;
    
    event ItemMinted(uint256 tokenId, address creator, uint256 price);
    event ItemSold(uint256 tokenId, address buyer, uint256 price);
    
    constructor() ERC721("MerchNFT", "MERCH") Ownable(msg.sender) {}
    
    function mint(string memory uri, uint256 price) external returns (uint256) {
        require(price > 0, "Invalid price");
        
        _tokenIds++;
        uint256 tokenId = _tokenIds;
        
        _mint(msg.sender, tokenId);
        _tokenURIs[tokenId] = uri;
        
        items[tokenId] = Item(price, msg.sender, true);
        
        emit ItemMinted(tokenId, msg.sender, price);
        return tokenId;
    }
    
    function buy(uint256 tokenId) external payable {
        Item storage item = items[tokenId];
        require(item.forSale, "Not for sale");
        require(msg.value >= item.price, "Insufficient payment");
        
        address seller = ownerOf(tokenId);
        uint256 fee = (item.price * platformFee) / 10000;
        
        _transfer(seller, msg.sender, tokenId);
        item.forSale = false;
        
        payable(seller).transfer(item.price - fee);
        payable(owner()).transfer(fee);
        
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }
        
        emit ItemSold(tokenId, msg.sender, item.price);
    }
    
    function list(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Invalid price");
        
        items[tokenId] = Item(price, msg.sender, true);
    }
    
    function unlist(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        items[tokenId].forSale = false;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token doesn't exist");
        return _tokenURIs[tokenId];
    }
    
    function setPlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high");
        platformFee = newFee;
    }
}