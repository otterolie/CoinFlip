const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(() => resolve(), ms);
  });
}

async function main() {
  const initialAmount = hre.ethers.utils.parseEther("0.001");

  const CoinFlip = await hre.ethers.getContractFactory("CoinFlip");
  const contract = await CoinFlip.deploy({ value: initialAmount });

  await contract.deployed();
  console.log(`CoinFlip deployed to ${contract.address}`);

  await sleep(45 * 1000);

  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
