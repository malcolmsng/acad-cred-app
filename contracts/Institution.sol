//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

// import "./AcceptanceVoting.sol"

contract Institution {
  enum institutionState {
    APPROVED,
    PENDING, //pending vote
    REJECTED
  }

  struct institution {
    string name;
    string country;
    string city;
    string latitude;
    string longitude;
    institutionState state;
    address owner;
  }

  uint256 public numInstitutions = 0;
  mapping(uint256 => institution) public instituitions;
  address _owner;

  // AcceptanceVoting acceptanceVotingContract;

  // constructor(AcceptanceVoting acceptanceVotingAddr) public {
  //   _owner = msg.sender;
  //   // acceptanceVotingContract = acceptanceVotingAddr;
  // }

  /**
    @dev Require contract owner only
   */
  modifier ownerOnly() {
    _;
  }

  /**
    @dev Require that the institution has been voted on
   */
  modifier votedOnly() {
    _;
  }

  modifier validInstitutionId(uint256 instId) {
    require(instId < numInstitutions, "The institution id is not valid");
    _;
  }

  /**
    @dev Create an institution
    @return instId The id of the institution that was added
   */
  function addInstitution() public ownerOnly returns (uint256 instId) {}

  /**
    @dev Delete an institution
    @param instId The id of the institution to delete
   */
  function deleteInstitution(uint256 instId) public ownerOnly {}

  /**
    @dev Approve an institution
    @param instId The id of the institution to approve
   */
  function approveInstitution(uint256 instId) public votedOnly {}

  //Getters
  function getInstitutionName(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return instituitions[instId].name;
  }

  function getInstitutionCountry(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return instituitions[instId].country;
  }

  function getInstitutionCity(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return instituitions[instId].city;
  }

  function getInstitutionLatitude(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return instituitions[instId].latitude;
  }

  function getInstitutionLongitude(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return instituitions[instId].longitude;
  }

  function getInstitutionState(
    uint256 instId
  ) public view validInstitutionId(instId) returns (institutionState) {
    return instituitions[instId].state;
  }

  function getInstitutionOwner(
    uint256 instId
  ) public view validInstitutionId(instId) returns (address) {
    return instituitions[instId].owner;
  }
}
