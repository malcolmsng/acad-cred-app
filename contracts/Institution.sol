//SPDX-License-Identifier: UNLICENSE
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./AcceptanceVoting.sol";

contract Institution {
  enum institutionState {
    APPROVED, //approved after vote
    PENDING, //pending voting
    REJECTED //rejected after vote
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

  event add_institution(
    address inst,
    string name,
    institutionState state,
    uint256 id
  );
  event approve_institution(address inst, string name, institutionState state);

  uint256 public numInstitutions = 0;
  mapping(uint256 => institution) public institutions;
  address _owner;

  AcceptanceVoting acceptanceVotingContract;

  constructor(AcceptanceVoting acceptanceVotingAddr) public {
    _owner = msg.sender;
    acceptanceVotingContract = acceptanceVotingAddr;
  }

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
    @param newInstitution The address of the institution to be added
    @param institutionName The name of the institution to be added
    @return instId The id of the institution that was added
   */
  function addInstitution(
    address newInstitution,
    string memory institutionName
  ) public ownerOnly returns (uint256 instId) {
    // Dummy code just to enable testing of credential functions
    institution memory newInst = institution(
      institutionName,
      "Singapore",
      "Singapore",
      "1.290270",
      "103.851959",
      institutionState.PENDING,
      newInstitution
    );
    // newInst.name = institutionName;
    // newInst.state = institutionState.PENDING;
    // newInst.owner = newInstitution;

    uint256 newInstitutionId = numInstitutions++;
    institutions[newInstitutionId] = newInst; // commit to state variable

    acceptanceVotingContract.addApplicant(
      newInstitutionId,
      msg.sender,
      institutionName
    );

    emit add_institution(
      institutions[newInstitutionId].owner,
      institutions[newInstitutionId].name,
      institutions[newInstitutionId].state,
      newInstitutionId
    );

    return newInstitutionId;
  }

  /**
    @dev Delete an institution
    @param instId The id of the institution to delete
   */
  function deleteInstitution(uint256 instId) public ownerOnly {}

  /**
    @dev Approve an institution
    @param instId The id of the institution to approve
   */
  function approveInstitution(uint256 instId) public votedOnly {
    // Dummy code just to enable testing of credential functions
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
    } else {
      institutions[instId].state = institutionState.PENDING;
    }
  }

  //Getters
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
