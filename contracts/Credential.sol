//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./Institution.sol";

contract Credential {
  enum credentialState {
    ACTIVE,
    DELETED,
    REVOKED,
    EXPIRED
  }

  struct credential {
    string studentName;
    string studentNumber;
    string courseName;
    string degreeLevel;
    string endorserName;
    string issuerName; //name of Institution
    uint issuanceDate;
    uint expiryDate;
    credentialState state;
    address issuer; //address of Institution
    address owner; //student (recipient of credential)
  }

  event add_credential(
    uint256 credId,
    address issuer,
    string issuerName,
    address owner,
    string studentName,
    string courseName
  );
  event delete_credential(
    address issuer,
    string issuerName,
    address owner,
    string studentName,
    string courseName
  );
  event revoke_credential(
    address issuer,
    string issuerName,
    address owner,
    string studentName,
    string courseName
  );

  uint256 public numCredentials = 0;
  mapping(uint256 => credential) public credentials;

  Institution institutionContract;

  constructor(Institution insitutionAddr) public {
    institutionContract = insitutionAddr;
  }

  /**
    @dev Require credential owner only
   */
  modifier ownerOnly(uint256 credId) {
    require(
      credentials[credId].owner == msg.sender,
      "Only the owner of the credential can call this function"
    );
    _;
  }

  /**
    @dev Require credential issuer only
   */
  modifier issuerOnly(uint256 credId) {
    require(
      credentials[credId].issuer == msg.sender,
      "Only the issuer of the credential can call this function"
    );
    _;
  }

  /**
    @dev Require valid credential id
    @param credId The id of the credential to check
   */
  modifier validCredentialId(uint256 credId) {
    require(credId < numCredentials, "The credential id is not valid");
    _;
  }

  /**
    @dev Require approved institution only
    @param instId The id of the institution to check
   */
  modifier approvedInstitutionOnly(uint256 instId) {
    require(
      institutionContract.getInstitutionState(instId) ==
        Institution.institutionState.APPROVED,
      "The institution must be approved to perform this function"
    );
    _;
  }

  /**
      @dev Create a credential
      @param studentName Name of student owner of credential
      @param studentNumber The student number of owner of credential
      @param courseName The name of the course or major the student studied
      @param degreeLevel The level of the degree earned by the student (e.g. bachelor's, master's)
      @param endorserName Name of authorised person who endorsed the credential
      @param institutionId The id of the institution
      @param issuanceDate The date the credential was issued
      @param expiryDate The date the credential expires (optional, 0 if null)
      @param student The address of the student owner of the credential
      @return credId The id of the credential that was added
     */
  function addCredential(
    string memory studentName,
    string memory studentNumber,
    string memory courseName,
    string memory degreeLevel,
    string memory endorserName,
    uint256 institutionId,
    uint issuanceDate,
    uint expiryDate, // optional, 0 if null
    address student
  )
    public
    payable
    approvedInstitutionOnly(institutionId)
    returns (uint256 credId)
  {
    require(msg.value >= 1E16, "At least 0.01ETH needed to create credential");

    require(bytes(studentName).length > 0, "Student name cannot be empty");
    require(bytes(studentNumber).length > 0, "Student number cannot be empty");
    require(bytes(courseName).length > 0, "Course name cannot be empty");
    require(bytes(degreeLevel).length > 0, "Degree level cannot be empty");
    require(bytes(endorserName).length > 0, "Endorser name cannot be empty");
    require(issuanceDate > 0, "Issuance date cannot be empty");
    require(
      issuanceDate <= block.timestamp,
      "Issuance date cannot be a future date. Please enter an issuance date that is today or in the past."
    );
    require(student != address(0), "Student address cannot be empty");

    // New credential object
    credential memory newCredential = credential(
      studentName,
      studentNumber,
      courseName,
      degreeLevel,
      endorserName,
      institutionContract.getInstitutionName(institutionId),
      issuanceDate,
      expiryDate,
      credentialState.ACTIVE,
      msg.sender, // Issuer (institution)
      student
    );

    uint256 newCredentialId = numCredentials++;
    credentials[newCredentialId] = newCredential; // commit to state variable

    emit add_credential(
      newCredentialId,
      msg.sender,
      newCredential.issuerName,
      newCredential.owner,
      newCredential.studentName,
      newCredential.courseName
    );
    return newCredentialId; // return new credentialId
  }

  /**
    @dev Delete an active credential to edit and reupload a credential
    @param credId The id of the credential to delete
   */
  function deleteCredential(
    uint256 credId
  ) public issuerOnly(credId) validCredentialId(credId) {
    require(
      credentials[credId].state != credentialState.DELETED,
      "Credential has already been deleted."
    );
    require(
      credentials[credId].state == credentialState.ACTIVE,
      "Only active credentials can be deleted."
    );

    // Lazy deletion, numCredentials does not change
    credentials[credId].state = credentialState.DELETED;

    emit delete_credential(
      msg.sender,
      credentials[credId].issuerName,
      credentials[credId].owner,
      credentials[credId].studentName,
      credentials[credId].courseName
    );
  }

  /**
    @dev Revoke an active credential
    @param credId The id of the credential to revoke
   */
  function revokeCredential(
    uint256 credId
  ) public issuerOnly(credId) validCredentialId(credId) {
    require(
      credentials[credId].state != credentialState.REVOKED,
      "Credential has already been revoked."
    );
    require(
      credentials[credId].state == credentialState.ACTIVE,
      "Only active credentials can be revoked"
    );

    credentials[credId].state = credentialState.REVOKED;

    emit revoke_credential(
      msg.sender,
      credentials[credId].issuerName,
      credentials[credId].owner,
      credentials[credId].studentName,
      credentials[credId].courseName
    );
  }

  /**
    @dev View all credentials
    @return _credentials An array of all credentials that have been created as a string
   */
  function viewAllCredentials()
    public
    view
    returns (string memory _credentials)
  {}

  /**
    @dev View credential by credId
    @param credId The id of the credential to view
    @return _credential The credential to be viewed as a string
   */
  function viewCredentialById(
    uint256 credId
  ) public view returns (string memory _credential) {}

  /**
    @dev View all credentials of student
    @param studentName The student name to view all the credentials of
    @return _credentials All the credentials of the student to be viewed as a string
  */
  function viewAllCredentialsOfStudent(
    string memory studentName
  ) public view returns (string memory _credentials) {}

  //Getters
  function getCredentialStudentName(
    uint256 credId
  ) public view validCredentialId(credId) returns (string memory) {
    return credentials[credId].studentName;
  }

  function getCredentialStudentNumber(
    uint256 credId
  )
    public
    view
    issuerOnly(credId)
    validCredentialId(credId)
    returns (string memory)
  {
    return credentials[credId].studentNumber;
  }

  function getCredentialCourseName(
    uint256 credId
  ) public view validCredentialId(credId) returns (string memory) {
    return credentials[credId].courseName;
  }

  function getCredentialDegreeLevel(
    uint256 credId
  ) public view validCredentialId(credId) returns (string memory) {
    return credentials[credId].degreeLevel;
  }

  function getCredentialEndorserName(
    uint256 credId
  ) public view validCredentialId(credId) returns (string memory) {
    return credentials[credId].endorserName;
  }

  function getCredentialIssuanceDate(
    uint256 credId
  ) public view validCredentialId(credId) returns (uint) {
    return credentials[credId].issuanceDate;
  }

  function getCredentialExpiryDate(
    uint256 credId
  ) public view validCredentialId(credId) returns (uint) {
    return credentials[credId].expiryDate;
  }

  function getCredentialState(
    uint256 credId
  )
    public
    view
    issuerOnly(credId)
    validCredentialId(credId)
    returns (credentialState)
  {
    return credentials[credId].state;
  }

  function getCredentialIssuer(
    uint256 credId
  ) public view validCredentialId(credId) returns (address) {
    return credentials[credId].issuer;
  }

  function getCredentialOwner(
    uint256 credId
  ) public view validCredentialId(credId) returns (address) {
    return credentials[credId].owner;
  }
}
