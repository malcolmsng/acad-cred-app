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

  /* 
  Account 1: Approve Institution - National University of Singapore
  Account 2: Pending Institution - Nanyang Technological University

  Account 4: Voting Member 1
  Account 5: Voting Member 2

  Account 7: Student A - Lyn
  Account 8: Student B - Keith
  Account 9: Student C - Remus
  */

  it('Add Approved Institution', async () => {
    // Create institution
    await institutionInstance.addInstitution('National University of Singapore', 'Singapore', 'Singapore', '1.290270', '103.851959', {
      from: accounts[1],
    });
    // Add voting committee members
    await acceptanceVotingInstance.addCommitteeMember(accounts[4]);
    await acceptanceVotingInstance.addCommitteeMember(accounts[5]);
    // 5 Eth applicant payment for voting
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
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );
    await assert.notStrictEqual(makeC1, undefined, 'Failed to add credential');
    truffleAssert.eventEmitted(makeC1, 'add_credential');

    let c1StudentName = await credentialInstance.getCredentialStudentName(0);
    await assert.strictEqual(c1StudentName, 'Lyn Tan', 'Credential created with incorrect student name');
    let c1CourseName = await credentialInstance.getCredentialCourseName(0);
    await assert.strictEqual(c1CourseName, 'Information Systems', 'Credential created with incorrect course name');

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
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );
    await assert.notStrictEqual(makeC2, undefined, 'Failed to add credential');
    truffleAssert.eventEmitted(makeC2, 'add_credential');

    let c2StudentName = await credentialInstance.getCredentialStudentName(1);
    await assert.strictEqual(c2StudentName, 'Keith Chan', 'Credential created with incorrect student name');
    let c2CourseName = await credentialInstance.getCredentialCourseName(1);
    await assert.strictEqual(c2CourseName, 'Artificial Intelligence Specialisation', 'Credential created with incorrect course name');
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
      { from: accounts[2] },
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

  it('View Credential by Id', async () => {
    // Add a credential (1st Credential of Remus)
    await credentialInstance.addCredential(
      'Remus Kwan',
      'A0223344L',
      'Computer Science',
      'Bachelor of Computing',
      'Dr Tan Keng Soon',
      0, // Institution ID
      toUnixTime(2023, 3, 26), // Issuance date
      toUnixTime(2028, 4, 21), // Expiry date
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );

    let credentialView = await credentialInstance.viewCredentialById(2, { from: accounts[1] });

    await assert.strictEqual(
      credentialView,
      `ID: 2\nStudent Name: Remus Kwan\nStudent Number: A0223344L\nCourse Name: Computer Science\nDegree Level: Bachelor of Computing\nEndorser Name: Dr Tan Keng Soon\nIssuance Date: 1679788800\nExpiry Date: 1839888000\nState: ACTIVE\n`,
      'Student credential info is not correct',
    );
  });

  it('View Credentials by Student Name', async () => {
    // Add a second credential (2nd Credential of Remus)
    await credentialInstance.addCredential(
      'Remus Kwan',
      'A0223344L',
      'Business Analytics',
      'Bachelor of Business Administration',
      'Dr Bock See',
      0, // Institution ID
      toUnixTime(2023, 3, 26), // Issuance date
      toUnixTime(2028, 4, 21), // Expiry date
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );

    let studentCredentials = await credentialInstance.viewAllCredentialsOfStudentByStudentName('Remus Kwan', { from: accounts[1] });

    await assert.strictEqual(
      studentCredentials,
      `ID: 2\nStudent Name: Remus Kwan\nStudent Number: A0223344L\nCourse Name: Computer Science\nDegree Level: Bachelor of Computing\nEndorser Name: Dr Tan Keng Soon\nIssuance Date: 1679788800\nExpiry Date: 1839888000\nState: ACTIVE\nID: 3\nStudent Name: Remus Kwan\nStudent Number: A0223344L\nCourse Name: Business Analytics\nDegree Level: Bachelor of Business Administration\nEndorser Name: Dr Bock See\nIssuance Date: 1679788800\nExpiry Date: 1839888000\nState: ACTIVE\n`,
      'Student credential info is not correct',
    );
  });

  it('View Credentials by Student Number', async () => {
    // Add a second credential (2nd Credential of Keith)
    // First credential of Keith is revoked
    await credentialInstance.addCredential(
      'Keith Chan',
      'A0654321K',
      'Law',
      'Bachelor of Laws',
      'Dr Lee Tiong Tsu',
      0, // Institution ID
      toUnixTime(2023, 3, 21), // Issuance date
      0, // Expiry date
      { from: accounts[1], value: oneEth.dividedBy(100) },
    );

    let studentCredentials = await credentialInstance.viewAllCredentialsOfStudentByStudentNumber('A0654321K', { from: accounts[1] });

    await assert.strictEqual(
      studentCredentials,
      `Credential for student Keith Chan has been revoked\nID: 4\nStudent Name: Keith Chan\nStudent Number: A0654321K\nCourse Name: Law\nDegree Level: Bachelor of Laws\nEndorser Name: Dr Lee Tiong Tsu\nIssuance Date: 1679356800\nExpiry Date: 0\nState: ACTIVE\n`,
      'Student credential info is not correct',
    );
  });

  it('Incorrect View Credential', async () => {
    // View credential with an invalid credential ID
    await truffleAssert.reverts(credentialInstance.viewCredentialById(5), 'The credential id is not valid');

    // View credential with invalid student name (no credentials under that student)
    await truffleAssert.reverts(
      credentialInstance.viewAllCredentialsOfStudentByStudentName('Malcolm Sng'),
      'Student name does not exist. There are no credentials under this student name.',
    );

    // View credential with invalid student number (no credentials under that student)
    await truffleAssert.reverts(
      credentialInstance.viewAllCredentialsOfStudentByStudentNumber('A9999999Z'),
      'Student number does not exist. There are no credentials under this student number.',
    );
  });

  it('View All Credentials', async () => {
    let allStudentCredentials = await credentialInstance.viewAllCredentials({ from: accounts[1] });

    // Observe that:
    // Id 0 (Lyn Tan) is not shown since credential was deleted, Id 1 (Keith Chan) credential was revoked
    // Id 2 and 3 for Remus's credentials, Id 4 for Keith credential shows up

    await assert.strictEqual(
      allStudentCredentials,
      `Credential for student Keith Chan has been revoked\nID: 2\nStudent Name: Remus Kwan\nStudent Number: A0223344L\nCourse Name: Computer Science\nDegree Level: Bachelor of Computing\nEndorser Name: Dr Tan Keng Soon\nIssuance Date: 1679788800\nExpiry Date: 1839888000\nState: ACTIVE\nID: 3\nStudent Name: Remus Kwan\nStudent Number: A0223344L\nCourse Name: Business Analytics\nDegree Level: Bachelor of Business Administration\nEndorser Name: Dr Bock See\nIssuance Date: 1679788800\nExpiry Date: 1839888000\nState: ACTIVE\nID: 4\nStudent Name: Keith Chan\nStudent Number: A0654321K\nCourse Name: Law\nDegree Level: Bachelor of Laws\nEndorser Name: Dr Lee Tiong Tsu\nIssuance Date: 1679356800\nExpiry Date: 0\nState: ACTIVE\n`,
      'Student credential info is not correct',
    );
  });

});
