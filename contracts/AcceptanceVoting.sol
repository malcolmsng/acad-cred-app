pragma solidity ^0.5.0;

contract AcceptanceVoting {
  // member address => true if exist
  mapping(address => bool) committeeMembers;
  // members => true if voted
  mapping(address => bool) hasVoted;
  uint32 committeeSize;
  address committeeChairman;
  // should we set a deadline to vote e.g. 1 week
  uint votingDeadline;
  VotingState currentState;

  enum VotingState {
    OPEN,
    CLOSED
  }

  // should the person who deploys the contract be the chairman?
  // or should we allocate the chairman
  constructor() public {
    currentState = VotingState.CLOSED;
  }

  function vote() external {}

  function openVote() external {}

  function closeVote() external {}

  function distributeFee() external payable {}

  // getters
  function getCommitteeChairman() external view returns (address) {
    return committeeChairman;
  }

  function getVotingDeadline() external view returns (uint) {
    return votingDeadline;
  }

  // will return the index of the voting state
  // i.e. VotingState.OPEN == 0
  function getVotingState() external view returns (VotingState) {
    return currentState;
  }
}
