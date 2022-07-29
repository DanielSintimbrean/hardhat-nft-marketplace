const { ethers, network } = require("hardhat")
const fs = require("fs")

const frontEndContractsFile = "../moralis/constants/networkMapping.json"

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("upada")
        await updateContractAddresses()
    }
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
