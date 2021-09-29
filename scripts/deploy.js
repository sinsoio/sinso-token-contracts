async function main() {
  const Token = await ethers.getContractFactory('Token')
  const deployed = await Token.deploy("0xx",100000000000000000000000000)
  console.log('Contract deployed to:', deployed.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
