pragma solidity ^0.5.0;

contract AcceptanceVoting {

  //List of committee members
  address[] committeeMembers; 
  // member address => true if exist
  mapping(address => bool) isCommitteeMember;
  // members => true if voted
  mapping(address => bool) hasVoted;
  // application fee
  uint256 applicationFee;
  //Size of commitee
  uint32 committeeSize;

  //Address of committee chariman
  address committeeChairman;
  // should we set a deadline to vote e.g. 1 week
  // Deadline in terms of blocks (1 eth block roughly 12.13 minutes)
  uint256 votingDeadline;

  uint256 voteOpenBlock;

  VotingState currentState;

  //Events
  event new_chairman(address newChairman);
  event new_committee_member(address newCommitteeMember);
  event new_committee_size(uint256 size);
  event voteOpen(uint256 blockNumber);
  event voteClose(uint256 blockNumber);

  enum VotingState {
    OPEN,
    CLOSED
  }

  // should the person who deploys the contract be the chairman?
  // or should we allocate the chairman
  constructor(uint256 fee, uint256 deadline) public {
    currentState = VotingState.CLOSED;
    committeeChairman = msg.sender;
    applicationFee = fee;
    votingDeadline = deadline;
  }

  modifier isChairman() {
    require(msg.sender == committeeChairman, "Only Chairman can call this function");
    _;
  }

  function vote() external {}

  function openVote() external isChairman {

    // Reset voting
    for (uint256 i = 0; i < committeeMembers.length; i++) {
      hasVoted[committeeMembers[i]] = false;
    }

    // Change voting state
    currentState = VotingState.OPEN;

    // Write vote open block
    voteOpenBlock = block.number;

    // Emit event
    emit voteOpen(block.number);
  }

  function closeVote() external isChairman {
    require(currentState == VotingState.OPEN, "Vote is not open");
    require(voteOpenBlock + votingDeadline >= block.number, "Deadline not up");

    // Calculate votes here
    
    emit voteClose(block.number);
  }

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

  function getFee() public view returns (uint256) {
    return applicationFee;
  }

  function getDeadline() public view returns (uint256) {
    return votingDeadline;
  }

  function getCommitteeMembers() public view returns (address[] memory) {
    return committeeMembers;
  }

  function changeDeadline(uint256 deadline) public isChairman {
    votingDeadline = deadline;
  }

  function changeFee(uint256 fee) public isChairman {
    applicationFee = fee;
  }

  function changeCommitteeSize(uint32 size) public isChairman {
    committeeSize = size;
    emit new_committee_size(size);
  }

  function removeCommiteeMember(address user) public isChairman {
    require(isCommitteeMember[user], "User is not a current committee Member");
    require(committeeMembers.length > 0, "Commitee is empty");
    isCommitteeMember[user] = false;

    // Remove address from committee member array without preserving order
    for (uint256 i = 0; i < committeeMembers.length; i++) {
      if (user == committeeMembers[i]) {
          // Replace current index with last element
          committeeMembers[i] = committeeMembers[committeeMembers.length-1];
          // Pop last element
          committeeMembers.pop();
      }
    }
  }

  function addCommitteeMember(address user) public isChairman {
    require(committeeMembers.length < committeeSize, "Max committee Members size");
    committeeMembers.push(user);
    isCommitteeMember[user] = true;
    emit new_committee_member(user);
  }

  function changeChairman(address user) public isChairman {
    committeeChairman = user;
    emit new_chairman(user);
  }

}
