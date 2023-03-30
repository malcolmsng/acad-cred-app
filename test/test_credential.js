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

contract('Credential Contract Unit Test', function (accounts) {
  before(async () => {
    acceptanceVotingInstance = await AcceptanceVoting.deployed();
    credentialInstance = await Credential.deployed();
    institutionInstance = await Institution.deployed();
  });

  console.log('Testing Institution and Acceptance Voting contract');

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

    let makeM1 = await acceptanceVotingInstance.addCommitteeMember(accounts[1]);
    truffleAssert.eventEmitted(makeM1, 'new_committee_member');

    let makeM2 = await acceptanceVotingInstance.addCommitteeMember(accounts[2]);
    truffleAssert.eventEmitted(makeM2, 'new_committee_member');

    // Attempt to pay 5 eth
    let app_paid = await acceptanceVotingInstance.acknowledgePay(0, accounts[1], {from: accounts[0], value: oneEth.multipliedBy(5) });
    truffleAssert.eventEmitted(app_paid, 'applicant_paid');

    let makeO1 = await acceptanceVotingInstance.openVote(0);

    let makeV1 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[1] });

    let makeV2 = await acceptanceVotingInstance.vote(0, true, true, true, true, true, { from: accounts[2] });

    await acceptanceVotingInstance.changeDeadline(0);
    let makeC1 = await acceptanceVotingInstance.closeVote(0, 9);
    await institutionInstance.updateInstitutionStatus(0);
    let makeS1 = await institutionInstance.updateInstitutionStatus(0);
    truffleAssert.eventEmitted(makeS1, 'approve_institution');
  });


  it('Add Credential', async () => {
    // Create a credential with an expiry date
    let makeC1 = await credentialInstance.addCredential(
      'Lyn Tan',
      'A0123456L',
      'Information Systems',
      'Bachelor of Computing',
      'Dr Li Xiaofan',
      0, // Institution ID
      toUnixTime(2023, 3, 21), // Issuance date
      toUnixTime(2028, 3, 21), // Expiry date
      //accounts[7], // Student A,
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );
    await assert.notStrictEqual(makeC1, undefined, 'Failed to add credential');
    truffleAssert.eventEmitted(makeC1, 'add_credential');

    // Create a credential without an expiry date
    let makeC2 = await credentialInstance.addCredential(
      'Keith Chan',
      'A0654321K',
      'Artificial Intelligence Specialisation',
      'Master of Computing',
      'Professor Tan Kian Lee',
      0, // Institution ID
      toUnixTime(2023, 3, 21), // Issuance date
      0, // Expiry date
      //accounts[8], // Student B,
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );
    await assert.notStrictEqual(makeC2, undefined, 'Failed to add credential');
    truffleAssert.eventEmitted(makeC2, 'add_credential');
  });

  it('Incorrect Add Credential', async () => {
    // Cannot add credential with less than 0.01 ETH
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        toUnixTime(2028, 3, 21), // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(1000) },
      ),
      'At least 0.01ETH needed to create credential',
    );

    // Create pending (not approved) institution
    let makeI3 = await institutionInstance.addInstitution(
      'Singapore Management University',
      'Singapore',
      'Singapore',
      '1.2963',
      '103.8502',
      { from: accounts[3] },
    );

    // Unapproved institutions cannot add credential
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        1, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        toUnixTime(2028, 3, 21), // Expiry date
        //accounts[7], // Student A,
        { from: accounts[2], value: oneEth.dividedBy(100) },
      ),
      'The institution must be approved to perform this function',
    );

    // Compulsory fields cannot be empty
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        '',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Student name cannot be empty',
    );

    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        '',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Student number cannot be empty',
    );
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        '',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Course name cannot be empty',
    );
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        '',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Degree level cannot be empty',
    );
    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        '',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Endorser name cannot be empty',
    );

    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        0, // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Issuance date cannot be empty',
    );

    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 8, 1), // Issuance date
        0, // Expiry date
        //accounts[7], // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Issuance date cannot be a future date. Please enter an issuance date that is today or in the past.',
    );

    /*
    // ensure studentAddress is an input of addCredential(), before uncommenting the 9th argument of the addCredential() function below

    await truffleAssert.reverts(
      credentialInstance.addCredential(
        'Lyn Tan',
        'A0123456L',
        'Information Systems',
        'Bachelor of Computing',
        'Dr Li Xiaofan',
        0, // Institution ID
        toUnixTime(2023, 3, 21), // Issuance date
        0, // Expiry date
        //zeroAddress, // Student A,
        { from: accounts[1], value: oneEth.dividedBy(100) },
      ),
      'Student address cannot be empty',
    );
    */
  });

  it('Delete Credential', async () => {
    let deleteC1 = await credentialInstance.deleteCredential(0, { from: accounts[1] });
    truffleAssert.eventEmitted(deleteC1, 'delete_credential');

    await truffleAssert.reverts(credentialInstance.deleteCredential(0, { from: accounts[1] }), 'Credential has already been deleted.');
  });

  it('Revoke Credential', async () => {
    let revokeC2 = await credentialInstance.revokeCredential(1, { from: accounts[1] });
    truffleAssert.eventEmitted(revokeC2, 'revoke_credential');

    await truffleAssert.reverts(credentialInstance.revokeCredential(1, { from: accounts[1] }), 'Credential has already been revoked.');

    await truffleAssert.reverts(credentialInstance.revokeCredential(0, { from: accounts[1] }), 'Only active credentials can be revoked');
  });

  it('Incorrect Delete Credential', async () => {
    await truffleAssert.reverts(credentialInstance.deleteCredential(1, { from: accounts[1] }), 'Only active credentials can be deleted');
  });
});
