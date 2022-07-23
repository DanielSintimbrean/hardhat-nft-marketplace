// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketpalceNotOwner();

contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }

    // NFT Contract address -> NFT TokenID -> Listing
    mapping (address => mapping(uint256 => Listing)) private s_listings;


    event ItemList(
        address indexed seller,
        address indexed nftAddess,
        uint256 indexed tokenId,
        uint256 price
    );

    /////////////////
    /// Modifiers ///
    /////////////////

    modifier noListed (address nftAddess, uint256 tokenId, address owner) {
        Listing memory  listing = s_listings[nftAddess][tokenId];
        if (listing.price > 0){
            revert NftMarketplace__AlreadyListed(nftAddess, tokenId);
        }
        _;
    }

    modifier isOwner (address nftAddess, uint256 tokenId, address spender) {
        IERC721 nft = IERC721(nftAddess);
        address owner = nft.ownerOf(tokenId);
        if (owner != spender){
            revert NftMarketpalceNotOwner();
        }
        _;
    }

    constructor() {
        
    }

    //////////////////////
    /// Main functions ///
    //////////////////////

    /**
     * @notice Method for listting yout NFT on the marketplace 
     * @param nftAddess: Adress of the NFT
     * @param tokenId: The TokenID of the NFT 
     * @param price: sale prince of the listed NFt
     **/
    function listItems (
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external 
      isOwner(nftAddress, tokenId, msg.sender)
      noListed(nftAddress, tokenId, msg.sender){
        if  (price <= 0){
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        // 2 Options
        //   1. Send the NFT to the contract. Transfer -> Contract "hold" the NFT 
        //   2. Owners can still hold their NFT, and give the marketplace approval 
        //      to sell the NFT 
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)){
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemList(msg.sender, nftAddress, tokenId, price);
    }
}