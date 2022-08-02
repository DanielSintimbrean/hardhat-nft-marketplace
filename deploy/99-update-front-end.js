const { ethers, network } = require("hardhat")
const fs = require("fs")

const frontEndContractsFile = "../moralis/constants/networkMapping.json"
const frontEndAbiLocations = "../moralis/constants/"

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("upada")
        await updateContractAddresses()
        await updateAbi()
    }
}

async function updateAbi() {
    const nftMarketpalce = await ethers.getContract("NftMarketplace")
    fs.writeFileSync(
        `${frontEndAbiLocations}NftMarketplace.json`,
        nftMarketpalce.interface.format(ethers.utils.FormatTypes.json)
    )

    const basicNft = await ethers.getContract("BasicNft")
    fs.writeFileSync(
        `${frontEndAbiLocations}BasicNft.json`,
        nftMarketpalce.interface.format(ethers.utils.FormatTypes.json)
    )
}

async function updateContractAddresses() {
    const nftMarketpalce = await ethers.getContract("NftMarketplace")
    const chainId = network.config.chainId.toString()

    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf-8"))

    if (chainId in contractAddresses) {
        if (!contractAddresses[chainId]["NftMarketplace"].includes(nftMarketpalce.address)) {
            contractAddresses[chainId]["NftMarketplace"].push(nftMarketpalce.address)
        }
    } else {
        contractAddresses[chainId] = { NftMarketplace: [nftMarketpalce.address] }
    }

    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}

module.exports.tags = ["all", "frontend"]
