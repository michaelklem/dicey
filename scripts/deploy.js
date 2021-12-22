const main = async () => {
  const [deployer] = await hre.ethers.getSigners();
  const accountBalance = await deployer.getBalance();

  console.log('Deploying contracts with account: ', deployer.address);
  console.log('Account balance: ', accountBalance.toString());
  // console.log('xxxx ' + hre.ethers.utils.parseEther('0.1')) // 100000000000000000
  // return
  const contractFactory = await hre.ethers.getContractFactory('DiceRoller');
  const contract = await contractFactory.deploy(
    "0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9", 
    "0xa36085F69e2889c224210F603D836748e7dC0088", 
    "0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4", 
    hre.ethers.utils.parseEther('0.1') // 100000000000000000
  );

  await contract.deployed();
  console.log('Contract address: ', contract.address);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

runMain();