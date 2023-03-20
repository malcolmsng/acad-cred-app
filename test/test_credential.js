const _deploy_contracts = require("../migrations/2_deploy_contracts");
const truffleAssert = require("truffle-assertions");
const BigNumber = require('bignumber.js'); // npm install bignumber.js
var assert = require("assert");

const oneEth = new BigNumber(1000000000000000000); // 1 eth

var Credential = artifacts.require("../contracts/Credential.sol");
var Institution = artifacts.require("../contracts/Institution.sol");

contract ('Credential', function(accounts){
    before( async() => {
        credentialInstance = await Credential.deployed();
        institutionInstance = await Institution.deployed();
    });

    console.log("Testing Credential contract");

    it('Add Credential', async() =>{

        // create approved and unapproved institution
        // test fail 
        // 1. never pay enough
        // 2. unapproved institution
        // 3. fields empty (one by one test)

        // test success
        // 1. credential created w the correct instances - just check id - ask keith to check it w view
        // 2. create one with expiry date, one without
        // 3. extra eth returned to issuer
    });

})