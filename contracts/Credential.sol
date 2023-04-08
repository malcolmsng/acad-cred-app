//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.17;
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
  }

  event add_credential(
    uint256 credId,
    address issuer,
    string issuerName,
    string studentName,
    string courseName
  );
  event delete_credential(
    address issuer,
    string issuerName,
    string studentName,
    string courseName
  );
  event revoke_credential(
    address issuer,
    string issuerName,
    string studentName,
    string courseName
  );

  uint256 public numCredentials = 0;

  // credentialId => credential
  mapping(uint256 => credential) public credentials;

  // student name => list of credential IDs
  mapping(string => uint256[]) public credentialIdsByStudentName;

  // student number => list of credential IDs
  mapping(string => uint256[]) public credentialIdsByStudentNumber;

  Institution institutionContract;

  constructor(Institution insitutionContractAddr) {
    institutionContract = insitutionContractAddr;
  }

  /**
    @dev Require credential issuer only
    @param credId The id of the credential to check
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
    @dev Require student to have at least one credential in the system
    @param studentName The name of the student to check
   */
  modifier validStudentName(string memory studentName) {
    require(
      credentialIdsByStudentName[studentName].length > 0,
      "Student name does not exist. There are no credentials under this student name."
    );
    _;
  }

  /**
    @dev Require student to have at least one credential in the system
    @param studentNumber The student number of the student to check
   */
  modifier validStudentNumber(string memory studentNumber) {
    require(
      credentialIdsByStudentNumber[studentNumber].length > 0,
      "Student number does not exist. There are no credentials under this student number."
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
    uint expiryDate // optional, 0 if null
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
      msg.sender // Issuer (institution)
    );

    // Commit to state variables
    uint256 newCredentialId = numCredentials++;
    credentials[newCredentialId] = newCredential;
    credentialIdsByStudentName[studentName].push(newCredentialId);
    credentialIdsByStudentNumber[studentNumber].push(newCredentialId);

    emit add_credential(
      newCredentialId,
      msg.sender,
      newCredential.issuerName,
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
  {
    string[] memory creds = new string[](numCredentials);
    for (uint256 i = 0; i < numCredentials; i++) {
      creds[i] = encodeCredentialToString(i);
    }
    _credentials = concat(creds);
  }

  /**
    @dev View credential by credId
    @param credId The id of the credential to view
    @return _credential The credential to be viewed as a string
   */
  function viewCredentialById(
    uint256 credId
  ) public view validCredentialId(credId) returns (string memory _credential) {
    _credential = encodeCredentialToString(credId);
  }

  /**
    @dev View all credentials of student
    @param studentName The student name to view all the credentials of
    @return _credentials All the credentials of the student to be viewed as a string
  */
  function viewAllCredentialsOfStudentByStudentNameAndInstitutionName(
    string memory studentName,
    string memory institutionName
  )
    public
    view
    validStudentName(studentName)
    returns (string memory _credentials)
  {
    string[] memory creds = new string[](numCredentials);
    for (uint256 i = 0; i < numCredentials; i++) {
      if (
        (keccak256(bytes(credentials[i].studentName)) ==
          keccak256(bytes(studentName))) &&
        (keccak256(bytes(credentials[i].issuerName)) ==
          keccak256(bytes(institutionName)))
      ) {
        creds[i] = encodeCredentialToString(i);
      }
    }
    _credentials = concat(creds);
  }

  /**
    @dev View all credentials of student
    @param studentNumber The student number to view all the credentials of
    @return _credentials All the credentials of the student to be viewed as a string
  */
  function viewAllCredentialsOfStudentByStudentNumberAndInstitutionName(
    string memory studentNumber,
    string memory institutionName
  )
    public
    view
    validStudentNumber(studentNumber)
    returns (string memory _credentials)
  {
    string[] memory creds = new string[](numCredentials);
    for (uint256 i = 0; i < numCredentials; i++) {
      if (
        (keccak256(bytes(credentials[i].studentNumber)) ==
          keccak256(bytes(studentNumber))) &&
        (keccak256(bytes(credentials[i].issuerName)) ==
          keccak256(bytes(institutionName)))
      ) {
        creds[i] = encodeCredentialToString(i);
      }
    }
    _credentials = concat(creds);
  }

  ///////////// Getter Functions /////////////

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

  ///////////// Helper Functions /////////////

  /**
    @dev Compare equality of 2 strings
    @param a First string to compare
    @param b Second string to compare first string against
  */
  function compareStrings(
    string memory a,
    string memory b
  ) private pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  /**
    @dev Encode a credential into a formatted string
    @param credId The id of the credential to encode
  */
  function encodeCredentialToString(
    uint256 credId
  ) private view returns (string memory) {
    credential memory c = credentials[credId];

    //Check for Revoked / Expired state of Credential
    if (compareStrings(credentialStateToString(c.state), "REVOKED")) {
      return
        string(
          abi.encodePacked(
            "Credential for student ",
            c.studentName,
            " has been revoked",
            "\n"
          )
        );
    } else if (compareStrings(credentialStateToString(c.state), "EXPIRED")) {
      return
        string(
          abi.encodePacked(
            "Credential for student ",
            c.studentName,
            " has expired",
            "\n"
          )
        );
    } else if (compareStrings(credentialStateToString(c.state), "DELETED")) {
      return "";
    }

    //If Active State
    //Do not display issuer address
    return
      string(
        abi.encodePacked(
          "ID: ",
          uint256ToString(credId),
          "\n",
          "Student Name: ",
          c.studentName,
          "\n",
          "Student Number: ",
          c.studentNumber,
          "\n",
          "Course Name: ",
          c.courseName,
          "\n",
          "Degree Level: ",
          c.degreeLevel,
          "\n",
          "Endorser Name: ",
          c.endorserName,
          "\n",
          "Issuance Date: ",
          uintToString(c.issuanceDate),
          "\n",
          "Expiry Date: ",
          uintToString(c.expiryDate),
          "\n",
          "State: ",
          credentialStateToString(c.state),
          "\n"
        )
      );
  }

  /**
    @dev Concat an array of strings into a string
    @param words The array of strings to concat
  */
  function concat(string[] memory words) private pure returns (string memory) {
    bytes memory output;
    for (uint256 i = 0; i < words.length; i++) {
      output = abi.encodePacked(output, words[i]);
    }
    return string(output);
  }

  /**
    @dev Convert uint into string
    @param _i uint to convert
  */
  function uintToString(uint _i) private pure returns (string memory) {
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
      k = k - 1;
      uint8 temp = uint8(48 + (_i % 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  /**
    @dev Convert uint256 into string
    @param _i uint256 to convert
  */
  function uint256ToString(uint256 _i) private pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0) {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = uint8(48 + (_i % 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  /**
    @dev Convert address into string
    @param _address addresss to convert
  */
  function addressToString(
    address _address
  ) private pure returns (string memory) {
    bytes32 value = keccak256(abi.encodePacked(_address));
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  /**
    @dev Convert credentialState into string
    @param _state credentialState to convert
  */
  function credentialStateToString(
    credentialState _state
  ) private pure returns (string memory state) {
    if (_state == credentialState.ACTIVE) {
      return "ACTIVE";
    } else if (_state == credentialState.REVOKED) {
      return "REVOKED";
    } else if (_state == credentialState.EXPIRED) {
      return "EXPIRED";
    } else if (_state == credentialState.DELETED) {
      return "DELETED";
    }
  }
}
