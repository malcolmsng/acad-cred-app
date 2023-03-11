//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

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

  constructor() public {}

  /**
    @dev Create an institution
    @return instId The id of the institution that was added
   */
  function addInstitution() public returns (uint256 instId) {}

  function approveInstitution(uint256 instId) public {}

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
