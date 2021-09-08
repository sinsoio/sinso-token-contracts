async function main() {
  const SinsoToken = await ethers.getContractFactory('SinsoToken')
  const deployed = await SinsoToken.deploy("0xx",100000000000000000000000000)
  console.log('Contract deployed to:', deployed.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
