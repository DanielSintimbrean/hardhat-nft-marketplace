// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__PriceNotMet(address nftAddres, uint256 tokenId, uint256 price);
error NftMarketpalce__NotOwner();
error NftMarketplace__NoProceeds();
error NftMarketPlace__TransferFailed();

contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }

    // NFT Contract address -> NFT TokenID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Seller address -> Amount earned
    mapping(address => uint256) private s_proceeds;

    event ItemList(
        address indexed seller,
        address indexed nftAddess,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(address indexed seller, address indexed nftAddess, uint256 indexed tokenId);

    /////////////////
    /// Modifiers ///
    /////////////////

    modifier noListed(
        address nftAddess,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddess][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddess, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddess, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddess][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListed(nftAddess, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddess,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddess);
        address owner = nft.ownerOf(tokenId);
        if (owner != spender) {
            revert NftMarketpalce__NotOwner();
        }
        _;
    }

    constructor() {}

    //////////////////////
    /// Main functions ///
    //////////////////////

    /**
     * @notice Method for listting yout NFT on the marketplace
     * @param nftAddress: Adress of the NFT
     * @param tokenId: The TokenID of the NFT
     * @param price: sale prince of the listed NFt
     **/
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external isOwner(nftAddress, tokenId, msg.sender) noListed(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        // 2 Options
        //   1. Send the NFT to the contract. Transfer -> Contract "hold" the NFT
        //   2. Owners can still hold their NFT, and give the marketplace approval
        //      to sell the NFT
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemList(msg.sender, nftAddress, tokenId, price);
    }

    // Sending the money to the user ❌
    // Have them withdraw the money ✅
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];

        if (msg.value < listedItem.price) {
            revert NftMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }

        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[nftAddress][tokenId]);

        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);
    }

    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemList(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProcceds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert NftMarketPlace__TransferFailed();
        }
    }

    /////////////////////////
    /// Getters functions ///
    /////////////////////////

    function getListings(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
