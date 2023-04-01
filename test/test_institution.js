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

contract('Institution Contract Unit Test', function (accounts) {
  before(async () => {
    acceptanceVotingInstance = await AcceptanceVoting.deployed();
    credentialInstance = await Credential.deployed();
    institutionInstance = await Institution.deployed();
  });

  /* 
  Account 1: Approve Institution - National University of Singapore
  Account 2: Deleted Institution - Nanyang University
  Account 3: Rejected Institution - National University of Singapura

  Account 4: Voting Member 1
  Account 5: Voting Member 2
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

  it('Incorrect Add Institution', async () => {
    // Institution name cannot be empty
    await truffleAssert.reverts(
      institutionInstance.addInstitution(
        '', // Empty institution name
        'Singapore',
        'Singapore',
        '1.290270',
        '103.851959',
        { from: accounts[0] },
      ),
      'Institution name cannot be empty',
    );

    // Institution country cannot be empty
    await truffleAssert.reverts(
      institutionInstance.addInstitution(
        'National University of Singapore',
        '', // Empty institution name
        'Singapore',
        '1.290270',
        '103.851959',
        { from: accounts[0] },
      ),
      'Institution country cannot be empty',
    );

    // Institution city cannot be empty
    await truffleAssert.reverts(
      institutionInstance.addInstitution(
        'National University of Singapore',
        'Singapore',
        '', // Empty institution city
        '1.290270',
        '103.851959',
        { from: accounts[0] },
      ),
      'Institution city cannot be empty',
    );

    // Institution latitude cannot be empty
    await truffleAssert.reverts(
      institutionInstance.addInstitution(
        'National University of Singapore',
        'Singapore',
        'Singapore',
        '', // Empty institution latitude
        '103.851959',
        { from: accounts[0] },
      ),
      'Institution latitude cannot be empty',
    );

    // Institution longitude cannot be empty
    await truffleAssert.reverts(
      institutionInstance.addInstitution(
        'National University of Singapore',
        'Singapore',
        'Singapore',
        '1.290270',
        '', // Empty institution longitude
        { from: accounts[0] },
      ),
      'Institution longitude cannot be empty',
    );
  });

  it('Delete Institution', async () => {
    await institutionInstance.addInstitution('Nanyang University', 'Singapore', 'Singapore', '1.290270', '103.851959', {
      from: accounts[2],
    });

    let deleteI1 = await institutionInstance.deleteInstitution(1, { from: accounts[0] });
    truffleAssert.eventEmitted(deleteI1, 'delete_institution');

    await truffleAssert.reverts(
      institutionInstance.deleteInstitution(1, { from: accounts[0] }),
      'Institution has already been deleted from the system.',
    );
  });

  it('Check approved status', async () => {
    // Set up voting committee
    await acceptanceVotingInstance.addCommitteeMember(accounts[4]);
    await acceptanceVotingInstance.addCommitteeMember(accounts[5]);
    // 5 Eth applicant payment for voting   //acknowledgePay is a temp function while the actual payment function is being built
    await acceptanceVotingInstance.payFee(0, accounts[1], { from: accounts[1], value: oneEth.multipliedBy(5) });
    // Vote to approve institution
    await acceptanceVotingInstance.openVote(0);
    await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[4] });
    await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[5] });
    await acceptanceVotingInstance.changeDeadline(0);
    await acceptanceVotingInstance.closeVote(0, 9);
    // Approve institution
    let makeS1 = await institutionInstance.updateInstitutionStatus(0);
    truffleAssert.eventEmitted(makeS1, 'approve_institution');
  });

  it('Check pending status', async () => {
    // Create new institution
    await institutionInstance.addInstitution('National University of Singapura', 'Singapore', 'Singapore', '1.1', '101.1', {
      from: accounts[3],
    });
    // Check pending status
    let makeS2 = await institutionInstance.updateInstitutionStatus(1);
    truffleAssert.eventEmitted(makeS2, 'pending_institution');
  });

  it('Check rejected status', async () => {
    // Vote for instutition
    await acceptanceVotingInstance.payFee(1, accounts[12], { from: accounts[12], value: oneEth.multipliedBy(5) });
    await acceptanceVotingInstance.openVote(1);
    await acceptanceVotingInstance.vote(1, true, true, true, true, true, { from: accounts[4] });
    await acceptanceVotingInstance.vote(1, false, false, true, true, false, { from: accounts[5] });
    await acceptanceVotingInstance.closeVote(1, 9);
    // Reject institution
    let makeS3 = await institutionInstance.updateInstitutionStatus(1);
    truffleAssert.eventEmitted(makeS3, 'rejected_institution');
  });
});
