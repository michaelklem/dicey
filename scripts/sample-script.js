// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const DiceRoller = await hre.ethers.getContractFactory("DiceRoller");
  const contract = await DiceRoller.deploy();

  await contract.deployed();

  console.log("contract deployed to:", contract.address);

  // let a1 = await contract.randomCheck()
  // console.log('random: ' + a1);

  // await sleep(2000);

  await contract.roll(3,6,3)

  // await sleep(3000);
  /*
  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);
    
  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);
    
  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);

  await contract.roll()
  a1 = await contract.randomCheck()
  console.log('random: ' + a1);
  */      
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
