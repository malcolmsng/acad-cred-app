pragma solidity >=0.5.0;

contract Instituition {
  struct institution {
    string name;
    string country;
    string city;
    string latitude;
    string longitude;
    address owner;
  }

  uint256 public numInstitutions = 0;
  mapping(uint256 => institution) public instituitions;

  constructor() public {}
}
