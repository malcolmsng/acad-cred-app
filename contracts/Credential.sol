//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./Institution.sol";

contract Credential {
  enum credentialState {
    ACTIVE,
    REVOKED
  }

  struct credential {
    string studentName;
    string studentNumber;
    string courseName;
    string degreeLevel;
    string endorserName;
    uint issuanceDate;
    uint expiryDate;
    credentialState state;
    address issuer; //address of Institution
    address owner;
  }

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
      @return credId The id of the credential that was added
     */
  function addCredential()
    public
    approvedInstitutionOnly(credId)
    returns (uint256 credId)
  {}

  /**
    @dev Delete a credential
    @param credId The id of the credential to delete
   */
  function deleteCredential(
    uint256 credId
  ) public approvedInstitutionOnly(credId) {}

  /**
    @dev Revoke a credential
    @param credId The id of the credential to revoke
   */
  function revokeCredential(
    uint256 credId
  ) public approvedInstitutionOnly(credId) {}

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
    @return _credential All the credentials of the student to be viewed as a string
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

  //helper method to convert uint256 into string
  function uint2str(uint _i) private pure returns (string memory) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint length;
    while (j != 0) {
        length++;
        j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint k = length;
    while (_i != 0) {
        k = k-1 ;
        uint8 temp = uint8(48 + _i % 10);
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  //helper method to convert address into string
  function addressToString(address _address) private pure returns (string memory) {
    bytes32 value = keccak256(abi.encodePacked(_address));
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
        str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  //helper method to convert credential state into string
  function credentialStateToString(credentialState _state) private pure returns (string memory) {
    if (_state == credentialState.ACTIVE) {
        return "ACTIVE";
    } else if (_state == credentialState.REVOKED) {
        return "REVOKED";
    } 
  }

}
