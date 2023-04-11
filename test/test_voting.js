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
  Account 0: Contract Deployer, Chairman

  Account 1: Voting Member 1
  Account 2: Voting Member 2
  Account 3: Removed Voting Member 3
  Account 4: Approve Institution - National University of Singapore

  Account 9: Applicant
  */

  it('Add Institution', async () => {
    // Create approved institution
    let makeI1 = await institutionInstance.addInstitution(
      'National University of Singapore',
      'Singapore',
      'Singapore',
      '1.290270',
      '103.851959',
      { from: accounts[4] },
    );
    await assert.notStrictEqual(makeI1, undefined, 'Failed to add institution');
    truffleAssert.eventEmitted(makeI1, 'add_institution');
  });

  it('Add member', async () => {
    // Add member
    let makeM1 = await acceptanceVotingInstance.addCommitteeMember(accounts[1]);
    truffleAssert.eventEmitted(makeM1, 'new_committee_member');

    let makeM2 = await acceptanceVotingInstance.addCommitteeMember(accounts[2]);
    truffleAssert.eventEmitted(makeM2, 'new_committee_member');

    let makeM3 = await acceptanceVotingInstance.addCommitteeMember(accounts[3]);
    truffleAssert.eventEmitted(makeM3, 'new_committee_member');

    cMembers = await acceptanceVotingInstance.getAmountOfCommitteeMembers();
    await assert.strictEqual(cMembers.toNumber(), 4, 'Add Committee Member does not work');
  });

  it('Incorrect add member', async () => {
    // User cannot add member if user is not a chairman
    await truffleAssert.reverts(
      acceptanceVotingInstance.addCommitteeMember(accounts[3], { from: accounts[1] }),
      'Only Chairman can call this function',
    );

    // Current members cannot be added again
    await truffleAssert.reverts(acceptanceVotingInstance.addCommitteeMember(accounts[3]), 'User is already a current committee Member');
  });

  it('Remove member', async () => {
    // Add member
    let makeM3 = await acceptanceVotingInstance.removeCommitteeMember(accounts[3]);
    truffleAssert.eventEmitted(makeM3, 'remove_committee_member');
    cMembers = await acceptanceVotingInstance.getAmountOfCommitteeMembers();
    await assert.strictEqual(cMembers.toNumber(), 3, 'Add Committee Member does not work');
  });

  it('Incorrect remove member', async () => {
    // User cannot remove member if user is not a chairman
    await truffleAssert.reverts(
      acceptanceVotingInstance.removeCommitteeMember(accounts[3], { from: accounts[1] }),
      'Only Chairman can call this function',
    );

    // non-members cannot be removed again
    await truffleAssert.reverts(acceptanceVotingInstance.removeCommitteeMember(accounts[5]), 'User is not a current committee Member');
  });

  it('Applicant pays fee to begin acceptance process', async () => {
    let before_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    // Attempt to pay less than 5 eth
    await truffleAssert.reverts(
      acceptanceVotingInstance.payFee(0, accounts[9], { from: accounts[9], value: oneEth }),
      'Application fee is 5 ETH',
    );
    // Attempt to pay 5 eth
    let app_paid = await acceptanceVotingInstance.payFee(0, accounts[9], { from: accounts[9], value: oneEth.multipliedBy(5) });
    truffleAssert.eventEmitted(app_paid, 'applicant_paid');
    // Attempt to pay again
    await truffleAssert.reverts(
      acceptanceVotingInstance.payFee(0, accounts[9], { from: accounts[9], value: oneEth.multipliedBy(5) }),
      'Applicant fee has been paid',
    );
    let after_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    let diff = after_balance - before_balance;
    await assert.strictEqual(diff, 5, 'Pay fee does not work');
  });

  it('Cannot vote when vote has not opened', async () => {
    // User cannot remove member if user is not a chairman
    await truffleAssert.reverts(
      acceptanceVotingInstance.vote(0, true, true, true, false, false, { from: accounts[1] }),
      'Applicant is not open for voting',
    );
  });

  it('Open vote', async () => {
    // Open vote
    let makeO1 = await acceptanceVotingInstance.openVote(0);
    truffleAssert.eventEmitted(makeO1, 'vote_open');
    let vstate01 = await acceptanceVotingInstance.getVotingState(0);
    assert.strictEqual(vstate01.toString(), '0', 'Failed to open vote');
  });

  it('Vote', async () => {
    await truffleAssert.reverts(
      acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[3] }),
      'You are not a committee member',
    );
    // Vote
    let makeV1 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[1] });
    truffleAssert.eventEmitted(makeV1, 'voted');

    let makeV2 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[2] });
    truffleAssert.eventEmitted(makeV2, 'voted');
  });

  it('Cannot close vote before deadline is up', async () => {
    // Too early to close vote
    await truffleAssert.reverts(acceptanceVotingInstance.closeVote(0, 9), 'Deadline not up');
  });

  it('Check vote close function, approved status and distribute fee function', async () => {
    // Check vote close function
    let balance1_init = new BigNumber(await web3.eth.getBalance(accounts[1])) / oneEth;
    let balance2_init = new BigNumber(await web3.eth.getBalance(accounts[2])) / oneEth;
    await acceptanceVotingInstance.changeDeadline(0);
    let contract_before_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    await acceptanceVotingInstance.closeVote(0, 9);

    // Check approved status
    await institutionInstance.updateInstitutionStatus(0);
    let makeS1 = await institutionInstance.getInstitutionState(0);
    assert.equal(makeS1.toString(), '0', 'Failed to approve institution');

    // Check distribution fee function
    let balance1_final = new BigNumber(await web3.eth.getBalance(accounts[1])) / oneEth;
    let balance2_final = new BigNumber(await web3.eth.getBalance(accounts[2])) / oneEth;
    let contract_after_balance = new BigNumber(await web3.eth.getBalance(acceptanceVotingInstance.address)) / oneEth;
    assert.strictEqual(contract_before_balance - contract_after_balance, 5, 'Distribute Fee not working for contract');
    assert.strictEqual(balance1_final - balance1_init > 2.49, true, 'Distribute Fee not working for account 1');
    assert.strictEqual(balance2_final - balance2_init > 2.49, true, 'Distribute Fee not working for account 2');
  });
});
