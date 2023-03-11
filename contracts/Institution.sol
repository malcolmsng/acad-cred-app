//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

// import "./AcceptanceVoting.sol"

contract Institution {
  struct institution {
    string name;
    string country;
    string city;
    string latitude;
    string longitude;
    address owner;
    bool approved;
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
    @dev Require owner only
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
  function getInstitutionName(uint256 instId) public view returns (string memory) {
    return instituitions[instId].name;
  }

  function getInstitutionCountry(uint256 instId) public view returns (string memory) {
    return instituitions[instId].country;
  }

  function getInstitutionCity(uint256 instId) public view returns (string memory) {
    return instituitions[instId].city;
  }

  function getInstitutionLatitude(uint256 instId) public view returns (string memory) {
    return instituitions[instId].latitude;
  }

  function getInstitutionLongitude(uint256 instId) public view returns (string memory) {
    return instituitions[instId].longitude;
  }

  function getInstitutionOwner(uint256 instId) public view returns (address) {
    return instituitions[instId].owner;
  }
}
