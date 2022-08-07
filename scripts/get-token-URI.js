const { ethers } = require("hardhat")

async function main() {
    const basicNft = await ethers.getContract("BasicNft")
    const TokenURI = await basicNft.tokenURI("0")
    console.log(`TokenURI: ${TokenURI}`)
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch((err) => {
        console.log(err)
        process.exit(1)
    })
