const { assert, expect } = require("chai")
const { network, deployments, ethers, getNamedAccounts } = require("hardhat")
const { developmentChains } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Nft Marketplace", function () {
          let nftMarketplace, basicNft, deployer, player
          const PRICE = ethers.utils.parseEther("0.1")
          const TOKEN_ID = 0
          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              player = (await ethers.getSigners())[1]

              await deployments.fixture(["all"])

              nftMarketplace = await ethers.getContract("NftMarketplace")
              basicNft = await ethers.getContract("BasicNft")

              await basicNft.mintNft()
              await basicNft.approve(nftMarketplace.address, TOKEN_ID)
          })

          it("List a NFT and buy it", async function () {
              await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)

              const listing = await nftMarketplace.getListing(basicNft.address, TOKEN_ID)

              assert(listing.price.toString() == PRICE.toString())
              assert(listing.seller.toString() == deployer.toString())

              const playerConncectedNftMarketPlace = nftMarketplace.connect(player)
              await playerConncectedNftMarketPlace.buyItem(basicNft.address, TOKEN_ID, {
                  value: PRICE,
              })

              const newOwner = await basicNft.ownerOf(TOKEN_ID)
              const deployerProceeds = await nftMarketplace.getProceeds(deployer)

              assert(newOwner.toString() == player.address.toString())
              assert(deployerProceeds.toString() == PRICE.toString())
          })

          it("List a NFT and cancell it", async function () {
              await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
              await nftMarketplace.cancelListing(basicNft.address, TOKEN_ID)

              const playerConncectedNftMarketPlace = nftMarketplace.connect(player)

              await expect(
                  playerConncectedNftMarketPlace.buyItem(basicNft.address, TOKEN_ID, {
                      value: PRICE,
                  })
              ).to.be.revertedWith(`NotListed("${basicNft.address}", ${TOKEN_ID})`)

              const newOwner = await basicNft.ownerOf(TOKEN_ID)
              const deployerProceeds = await nftMarketplace.getProceeds(deployer)

              assert(newOwner.toString() == deployer.toString())
              assert(deployerProceeds.toString() == "0")
          })

          it("List a NFT and modify it", async function () {
              const PRICE_X2 = ethers.utils.parseEther("0.2")

              await nftMarketplace.listItem(basicNft.address, TOKEN_ID, PRICE)
              await nftMarketplace.updateListing(basicNft.address, TOKEN_ID, PRICE_X2)

              const playerConncectedNftMarketPlace = nftMarketplace.connect(player)

              await expect(
                  playerConncectedNftMarketPlace.buyItem(basicNft.address, TOKEN_ID, {
                      value: PRICE,
                  })
              ).to.be.revertedWith(`PriceNotMet("${basicNft.address}", ${TOKEN_ID}, ${PRICE_X2})`)

              const newOwner = await basicNft.ownerOf(TOKEN_ID)
              const deployerProceeds = await nftMarketplace.getProceeds(deployer)

              assert(newOwner.toString() == deployer.toString())
              assert(deployerProceeds.toString() == "0")
          })
      })
