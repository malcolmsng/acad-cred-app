//SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "./AcceptanceVoting.sol";

contract Institution {
  enum institutionState {
    APPROVED, //approved after vote
    PENDING, //pending voting
    REJECTED, //rejected after vote
    DELETED
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

  event add_institution(string name, uint256 id);

  event delete_institution(uint256 id);

  event approve_institution(address inst, string name, institutionState state);

  event pending_institution(address inst, string name, institutionState state);

  event rejected_institution(address inst, string name, institutionState state);

  uint256 public numInstitutions = 0;
  mapping(uint256 => institution) public institutions;
  address _owner;

  AcceptanceVoting acceptanceVotingContract;

  constructor(AcceptanceVoting acceptanceVotingAddr) {
    _owner = msg.sender;
    acceptanceVotingContract = acceptanceVotingAddr;
  }

  /**
    @dev Require contract owner only
   */
  modifier ownerOnly() {
    require(
      msg.sender == _owner,
      "Only the contract owner can call this function"
    );
    _;
  }

  modifier validInstitutionId(uint256 instId) {
    require(instId < numInstitutions, "The institution id is not valid");
    _;
  }

  /**
    @dev Create an institution
    @param institutionName The name of the institution to be added
    @param institutionCountry The country of the institution to be added
    @param institutionCity The city of the institution to be added
    @param institutionLatitude The latitude of the institution to be added
    @param institutionLongitude The longitude of the institution to be added
    @return instId The id of the institution that was added
   */
  function addInstitution(
    string memory institutionName,
    string memory institutionCountry,
    string memory institutionCity,
    string memory institutionLatitude,
    string memory institutionLongitude
  ) public returns (uint256 instId) {
    require(
      bytes(institutionName).length > 0,
      "Institution name cannot be empty"
    );
    require(
      bytes(institutionCountry).length > 0,
      "Institution country cannot be empty"
    );
    require(
      bytes(institutionCity).length > 0,
      "Institution city cannot be empty"
    );
    require(
      bytes(institutionLatitude).length > 0,
      "Institution latitude cannot be empty"
    );
    require(
      bytes(institutionLongitude).length > 0,
      "Institution longitude cannot be empty"
    );

    institution memory newInst = institution(
      institutionName,
      institutionCountry,
      institutionCity,
      institutionLatitude,
      institutionLongitude,
      institutionState.PENDING,
      msg.sender
    );

    uint256 institutionId = numInstitutions;
    institutions[institutionId] = newInst;
    numInstitutions++;

    acceptanceVotingContract.addApplicant(
      institutionId,
      msg.sender,
      institutionName
    );

    emit add_institution(institutionName, institutionId);

    return institutionId;
  }

  /**
    @dev Delete an institution
    @param instId The id of the institution to delete
   */
  function deleteInstitution(
    uint256 instId
  ) public ownerOnly validInstitutionId(instId) {
    require(
      institutions[instId].state != institutionState.DELETED,
      "Institution has already been deleted from the system."
    );
    institutions[instId].state = institutionState.DELETED;
    emit delete_institution(instId);
  }

  /**
    @dev Update an institution status
    @param instId The id of the institution to approve
   */
  function updateInstitutionStatus(
    uint256 instId
  ) public ownerOnly validInstitutionId(instId) {
    bool approvalResult = acceptanceVotingContract.checkApproved(instId);
    bool votingConcluded = acceptanceVotingContract.checkConcluded(instId);

    if (approvalResult == true) {
      institutions[instId].state = institutionState.APPROVED;

      emit approve_institution(
        institutions[instId].owner,
        institutions[instId].name,
        institutions[instId].state
      );
    } else if ((approvalResult != true) && (votingConcluded == true)) {
      institutions[instId].state = institutionState.REJECTED;

      emit rejected_institution(
        institutions[instId].owner,
        institutions[instId].name,
        institutions[instId].state
      );
    } else {
      institutions[instId].state = institutionState.PENDING;

      emit pending_institution(
        institutions[instId].owner,
        institutions[instId].name,
        institutions[instId].state
      );
    }
  }

  ///////////// Getter Functions /////////////
  
  function getInstitutionName(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return institutions[instId].name;
  }

  function getInstitutionCountry(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return institutions[instId].country;
  }

  function getInstitutionCity(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return institutions[instId].city;
  }

  function getInstitutionLatitude(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return institutions[instId].latitude;
  }

  function getInstitutionLongitude(
    uint256 instId
  ) public view validInstitutionId(instId) returns (string memory) {
    return institutions[instId].longitude;
  }

  function getInstitutionState(
    uint256 instId
  ) public view validInstitutionId(instId) returns (institutionState) {
    return institutions[instId].state;
  }

  function getInstitutionOwner(
    uint256 instId
  ) public view validInstitutionId(instId) returns (address) {
    return institutions[instId].owner;
  }
}
