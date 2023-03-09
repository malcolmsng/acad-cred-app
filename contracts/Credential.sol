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
    string issuer; //change to Institution
    bool revoked;
  }

  uint256 public numCredentials = 0;
  mapping(uint256 => credential) public credentials;

  Institution institutionContract;

  constructor(address insitutionAddr) public {
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
  function addCredential()
    public
    approvedInstitutionOnly
    returns (uint256 credId)
  {}

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
    @return _credentials
   */
  function viewAllCredentials()
    public
    view
    returns (credential[] memory _credentials)
  {}

  /**
    @dev View credential by credId
    @param credId
    @return _credential
   */
  function viewCredentialById(
    uint256 credId
  ) public view returns (credential memory _credential) {}

  /**
  @dev View all credentials of student
  @param studentName
 */
  function viewAllCredentialsOfStudent(
    string memory studentName
  ) public view returns (credential[] memory _credentials) {}
}
