//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./Institution.sol";

contract Credential {
  struct credential {
    string studentName;
    string studentNumber;
    string courseName;
    string degreeLevel;
    string endorserName;
    uint issuanceDate;
    uint expiryDate;
    address issuer; //address of Institution
    bool revoked;
  }

  uint256 public numCredentials = 0;
  mapping(uint256 => credential) public credentials;

  Institution institutionContract;

  constructor(Institution insitutionAddr) public {
    institutionContract = insitutionAddr;
  }

  /**
    @dev Require approved institution only
   */
  modifier approvedInstitutionOnly() {
    _;
  }

  /**
      @dev Create a credential
      @return credId The id of the credential that was added
     */
  function addCredential() public approvedInstitutionOnly returns (uint256 credId) {}

  /**
    @dev Delete a credential
   */
  function deleteCredential() public approvedInstitutionOnly {}

  /**
    @dev Revoke a credential
   */
  function revokeCredential() public approvedInstitutionOnly {}

  /**
    @dev View all credentials
    @return _credentials An array of all credentials that have been created as a string
   */
  function viewAllCredentials() public view returns (string memory _credentials) {}

  /**
    @dev View credential by credId
    @param credId The id of the credential to view
    @return _credential The credential to be viewed as a string
   */
  function viewCredentialById(uint256 credId) public view returns (string memory _credential) {}

  /**
    @dev View all credentials of student
    @param studentName The student name to view all the credentials of
    @return _credential All the credentials of the student to be viewed as a string
  */
  function viewAllCredentialsOfStudent(string memory studentName) public view returns (string memory _credentials) {}

  //Getters
  function getCredentialStudentName(uint256 credId) public view returns (string memory) {
    return credentials[credId].studentName;
  }

  function getCredentialStudentNumber(uint256 credId) public view returns (string memory) {
    return credentials[credId].studentNumber;
  }

  function getCredentialCourseName(uint256 credId) public view returns (string memory) {
    return credentials[credId].courseName;
  }

  function getCredentialDegreeLevel(uint256 credId) public view returns (string memory) {
    return credentials[credId].degreeLevel;
  }
}
