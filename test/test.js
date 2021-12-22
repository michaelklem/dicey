const { expect } = require('chai');

const truffleAssert = require('truffle-assertions');
const { ethers } = require("hardhat");
// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { fail } = require('assert');
const exp = require('constants');
const DiceRoller = artifacts.require("DiceRoller");

  // kovan
  // link = 0xa36085F69e2889c224210F603D836748e7dC0088
  // vrf coordinator = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
  // keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
  // 0.1 LINK = 100000000000000000
  // constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee)
  // deployed contract address: 0x400e7b55Cf4C971CcA8B2294e493Ff254cCA00Bc

contract('DiceRoller', function ([ owner, other ]) {
  beforeEach(async function () {
    this.contract = await DiceRoller.attach("0x400e7b55Cf4C971CcA8B2294e493Ff254cCA00Bc");
  })


  it('stores a positive value when wasRolled is called', async function () {
    await this.contract.getAllUsers();
    console.log('done')
  })


})