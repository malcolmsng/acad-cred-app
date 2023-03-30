const _deploy_contracts = require('../migrations/2_deploy_contracts');
const truffleAssert = require('truffle-assertions');
const BigNumber = require('bignumber.js'); // npm install bignumber.js
var assert = require('assert');

const oneEth = new BigNumber(1000000000000000000); // 1 eth
const zeroAddress = '0x0000000000000000000000000000000000000000';

const toUnixTime = (year, month, day) => {
  const date = new Date(Date.UTC(year, month - 1, day));
  return Math.floor(date.getTime() / 1000);
};

const toDate = unixTimestamp => new Date(unixTimestamp * 1000);

var AcceptanceVoting = artifacts.require('../contracts/AcceptanceVoting.sol');
var Credential = artifacts.require('../contracts/Credential.sol');
var Institution = artifacts.require('../contracts/Institution.sol');

contract('AcceptanceVoting Contract Unit Test', function (accounts) {
  before(async () => {
    acceptanceVotingInstance = await AcceptanceVoting.deployed();
    credentialInstance = await Credential.deployed();
    institutionInstance = await Institution.deployed();
  });

  /* 
  Account 1: Approve Institution - National University of Singapore

  Account 4: Voting Member 1
  Account 5: Voting Member 2
  Account 6: Removed Voting Member 3
  */

  it('Add Institution', async () => {
    // Create approved institution
    let makeI1 = await institutionInstance.addInstitution(
      'National University of Singapore',
      'Singapore',
      'Singapore',
      '1.290270',
      '103.851959',
      { from: accounts[1] },
    );
    await assert.notStrictEqual(makeI1, undefined, 'Failed to add institution');
    truffleAssert.eventEmitted(makeI1, 'add_institution');
  });

  it('Add committee member', async () => {
    // Add committee member
    let makeM1 = await acceptanceVotingInstance.addCommitteeMember(accounts[4]);
    truffleAssert.eventEmitted(makeM1, 'new_committee_member');

    let makeM2 = await acceptanceVotingInstance.addCommitteeMember(accounts[5]);
    truffleAssert.eventEmitted(makeM2, 'new_committee_member');

    let makeM3 = await acceptanceVotingInstance.addCommitteeMember(accounts[6]);
    truffleAssert.eventEmitted(makeM3, 'new_committee_member');

    cMembers = await acceptanceVotingInstance.getAmountOfCommitteeMembers();
    await assert.strictEqual(cMembers.toNumber(), 4, 'Add Committee Member does not work');
  });

  it('Incorrect add member', async () => {
    // User cannot add member if user is not a chairman
    await truffleAssert.reverts(
      acceptanceVotingInstance.addCommitteeMember(accounts[6], { from: accounts[1] }),
      'Only Chairman can call this function',
    );

    // Current members cannot be added again
    await truffleAssert.reverts(acceptanceVotingInstance.addCommitteeMember(accounts[4]), 'User is already a current committee Member');
  });

  it('Remove member', async () => {
    // Add member
    let makeM3 = await acceptanceVotingInstance.removeCommitteeMember(accounts[6]);
    truffleAssert.eventEmitted(makeM3, 'remove_committee_member');
  });

  it('Incorrect remove member', async () => {
    // User cannot remove member if user is not a chairman
    await truffleAssert.reverts(
      acceptanceVotingInstance.removeCommitteeMember(accounts[4], { from: accounts[5] }),
      'Only Chairman can call this function',
    );

    // non-members cannot be removed again
    await truffleAssert.reverts(acceptanceVotingInstance.removeCommitteeMember(accounts[6]), 'User is not a current committee Member');
  });

  it('Applicant pays fee to begin acceptance process', async () => {
    let before_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    
    /*
    // Attempt to pay less than 5 eth
    await truffleAssert.reverts(
      acceptanceVotingInstance.payFee(0, accounts[1], { from: accounts[10], value: oneEth }),
      'Application fee is 5 ETH',
    );

    // Attempt to pay 5 eth
    let app_paid = await acceptanceVotingInstance.payFee(0, accounts[1], { from: accounts[10], value: oneEth.multipliedBy(5) });
    truffleAssert.eventEmitted(app_paid, 'applicant_paid');

    // Attempt to pay again
    await truffleAssert.reverts(
      acceptanceVotingInstance.payFee(0, accounts[1], { from: accounts[1], value: oneEth.multipliedBy(5) }),
      'Applicant fee has been paid',
    );

    let after_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    let diff = after_balance - before_balance;
    await assert.strictEqual(diff, 5, 'Pay fee does not work');
    */

    // Attempt to pay 5 eth
    let app_paid = await acceptanceVotingInstance.acknowledgePay(0, accounts[1], {from: accounts[1], value: oneEth.multipliedBy(5) });
    truffleAssert.eventEmitted(app_paid, 'applicant_paid');

    // Attempt to pay again
    await truffleAssert.reverts(
      acceptanceVotingInstance.acknowledgePay(0, accounts[1], { from: accounts[1], value: oneEth.multipliedBy(5) }),
      'Applicant fee has been paid',
    );
    
  });

  it('Cannot vote when vote has not opened', async () => {
    // User cannot vote if vote has not opened
    await truffleAssert.reverts(
      acceptanceVotingInstance.vote(0, true, true, true, false, false, { from: accounts[4] }),
      'Applicant is not open for voting',
    );
  });

  it('Open vote', async () => {
    // Open vote
    // let pay1 = await acceptanceVotingInstance.payFee(1, { from: accounts[1], value: 5e18 });
    let makeO1 = await acceptanceVotingInstance.openVote(0);
    truffleAssert.eventEmitted(makeO1, 'vote_open');
  });

  it('Vote', async () => {
    // Open vote
    let makeV1 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[4] });
    truffleAssert.eventEmitted(makeV1, 'voted');

    let makeV2 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[5] });

    truffleAssert.eventEmitted(makeV2, 'voted');
  });

  it('Cannot close vote', async () => {
    // Too early to close vote
    await truffleAssert.reverts(acceptanceVotingInstance.closeVote(0, 9), 'Deadline not up');
  });

  it('Close vote', async () => {
    // Close vote
    await acceptanceVotingInstance.changeDeadline(0);
    let makeC1 = await acceptanceVotingInstance.closeVote(0, 9);
    truffleAssert.eventEmitted(makeC1, 'vote_close');
  });

  it('Check distribute fee', async () => {
    /*
    // await acceptanceVotingInstance.closeVote(2,0)
    await acceptanceVotingInstance.addApplicant(2, zeroAddress, 'SIT');
    await acceptanceVotingInstance.payFee(2, { from: accounts[5], value: 5e18 });
    await acceptanceVotingInstance.openVote(2);
    await acceptanceVotingInstance.vote(2, true, true, true, true, true, { from: accounts[6] });
    await acceptanceVotingInstance.vote(2, true, true, true, true, true, { from: accounts[7] });
    let balance1 = await web3.eth.getBalance(accounts[6]);
    await acceptanceVotingInstance.distributeFee(2);
    let balance2 = await web3.eth.getBalance(accounts[6]);
    await assert.notStrictEqual(balance1, balance2, 'Failed to distribute fee');
    */
  });


});
