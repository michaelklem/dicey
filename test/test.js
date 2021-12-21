const { expect } = require('chai');

const truffleAssert = require('truffle-assertions');
const { ethers } = require("hardhat");
// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { fail } = require('assert');
const exp = require('constants');
const DiceRoller = artifacts.require("DiceRoller");

contract('DiceRoller', function ([ owner, other ]) {
  beforeEach(async function () {
    this.contract = await DiceRoller.new({ from: owner });
  });

  it('stores a positive value when wasRolled is called', async function () {
    const numberOfDice = 3;
    const dieSize = 2;
    const adjustment = 5;
    const result = 13;

    await this.contract.wasRolled( numberOfDice, dieSize, adjustment, result);
    const contractResult = await this.contract.getUserRolls(owner);
    console.log('xxx ' + JSON.stringify(contractResult));
    expect(contractResult.length).to.equal(1);  

    const returnedValues = contractResult[0];
    expect(parseInt(returnedValues[0])).to.equal(numberOfDice);
    expect(parseInt(returnedValues[1])).to.equal(dieSize);
    expect(parseInt(returnedValues[2])).to.equal(adjustment);
    expect(parseInt(returnedValues[3])).to.equal(result);
  });

  it('stores a negative value when wasRolled is called', async function () {
    const numberOfDice = 3;
    const dieSize = 2;
    const adjustment = -5;
    const result = -13;

    await this.contract.wasRolled( numberOfDice, dieSize, adjustment, result);
    const contractResult = await this.contract.getUserRolls(owner);
    console.log('xxx ' + JSON.stringify(contractResult));
    expect(contractResult.length).to.equal(1);  

    const returnedValues = contractResult[0];
    expect(parseInt(returnedValues[0])).to.equal(numberOfDice);
    expect(parseInt(returnedValues[1])).to.equal(dieSize);
    expect(parseInt(returnedValues[2])).to.equal(adjustment);
    expect(parseInt(returnedValues[3])).to.equal(result);
  });

  /*
  it('emits the DiceWasRolled event when roll is called', async function () {
    const tx = await this.contract.roll(1,1,1);
    console.log('tx: ' + JSON.stringify(tx.logs))

    truffleAssert.eventEmitted(tx, 'DiceWasRolled', (ev) => {
        assert.equal(ev.result.toNumber(), 6, 'Correct result was returned');
        return true;
    });


    const users = await this.contract.getAllUsers();
    expect(users.length).to.equal(1);  
  });
  */

  /*
  it('throws an error if an empty string is passed as dice type', async function () {
    try {
      await this.contract.roll(1,1, 0);
      assert.fail('we expected an exception')
    }
    catch(err) {
      console.log('Error: ' + err)
      expect( err.toString().indexOf('Expected a non-empty roll type')).to.be.greaterThan(-1)
    }
  });
  */
})

/*
// Start test block
describe('DiceRoller', function () {
  let accounts; 

  before(async function () {
    accounts = await web3.eth.getAccounts();

    // this.DiceRoller = await ethers.getContractFactory('DiceRoller');
    this.DiceRoller = await DiceRoller.new('DiceRoller');
  });

  beforeEach(async function () {
    // const [owner, randomPerson] = await hre.ethers.getSigners();
    // this.contract = await this.DiceRoller.deploy("sdf");
    // this.owner = owner;
    // await this.contract.deployed();
    // console.log("Contract deployed to:", this.contract.address);
    // console.log("Contract deployed by:", this.owner.address);
  });

  // Test case
  it('will save sender address and generate a roll when roll is called', async function () {
    const transactionHash = await this.contract.roll();
    await expectEvent.inTransaction(transactionHash, this.contract, 'DiceWasRolled', { value: 7 });


    // const rollTx = await this.contract.roll();

    // Test that a ValueChanged event was emitted with the new value
    // expectEvent.inTransaction(rollTx, this.contract, 'DiceWasRolled', { value: 6 });

    // Test if the returned value is the same one
    // Note that we need to use strings to compare the 256 bit integers
    // const users = await this.contract.getAllUsers();
    // console.log("result: " + users.length );
    // expect(users.length).to.equal(1);  
  });
  
});*/