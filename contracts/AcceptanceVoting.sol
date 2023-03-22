pragma solidity ^0.5.0;

contract AcceptanceVoting {
  //List of committee members, chairman is part of committee members
  address[] committeeMembers;
  // member address => true if exist
  mapping(address => bool) isCommitteeMember;

  // members => candidate => true if voted
  mapping(address => mapping(uint256 => bool)) hasVoted;

  // applicant => votes it got
  mapping(uint256 => uint256) candidateVoteScore;

  // applicant => voting status
  mapping(uint256 => VotingState) candidateVotingState;

  // applicant => vote open block number
  mapping(uint256 => uint256) candidateVoteOpenBlock;

  // application fee in wei
  uint256 applicationFee;
  //Size of commitee
  uint32 committeeSize;

  //Address of committee chariman
  address committeeChairman;
  // should we set a deadline to vote e.g. 1 week
  // Deadline in terms of blocks (1 eth block roughly 12.13 minutes)
  uint256 votingDeadline;

  VotingState currentState;

  //Events
  event new_chairman(address newChairman);
  event new_committee_member(address newCommitteeMember);
  event new_committee_size(uint256 size);
  event voted(
    address committeeMember,
    uint256 candidateNumber,
    uint256 voteScore
  );
  event vote_open(uint256 candidateNumber, uint256 blockNumber);
  event vote_close(uint256 candidateNumber, uint256 blockNumber);
  event vote_results(
    string outcome,
    uint256 candidateNumber,
    uint256 candidateScore,
    uint256 scoreNeeded
  );

  enum VotingState {
    OPEN,
    CLOSED
  }

  // should the person who deploys the contract be the chairman?
  // or should we allocate the chairman
  constructor(uint256 fee, uint256 deadline) public {
    committeeChairman = msg.sender;
    applicationFee = fee;
    votingDeadline = deadline;
    addCommitteeMember(msg.sender);
  }

  modifier isChairman() {
    require(
      msg.sender == committeeChairman,
      "Only Chairman can call this function"
    );
    _;
  }

  function vote(
    uint256 candidateNumber,
    bool criteria_1,
    bool criteria_2,
    bool criteria_3,
    bool criteria_4,
    bool criteria_5
  ) external {
    require(isCommitteeMember[msg.sender], "You are not a committee member");
    require(
      candidateVotingState[candidateNumber] == VotingState.OPEN,
      "Candidate not open for voting"
    );
    hasVoted[msg.sender][candidateNumber] = true;

    // Do voting calculation
    uint256 vote_score = 0;
    if (criteria_1) {
      vote_score++;
    }
    if (criteria_2) {
      vote_score++;
    }
    if (criteria_3) {
      vote_score++;
    }
    if (criteria_4) {
      vote_score++;
    }
    if (criteria_5) {
      vote_score++;
    }

    // Add committee member vote score to total vote score
    candidateVoteScore[candidateNumber] += vote_score;

    emit voted(msg.sender, candidateNumber, vote_score);
  }

  function openVote(uint256 candidateNumber) external isChairman {
    require(
      candidateVotingState[candidateNumber] == VotingState.CLOSED,
      "Candidate already undergoing voting"
    );

    // Change voting state
    candidateVotingState[candidateNumber] = VotingState.OPEN;

    // Write vote open block
    candidateVoteOpenBlock[candidateNumber] = block.number;

    // Emit event
    emit vote_open(candidateNumber, block.number);
  }

  function closeVote(
    uint256 candidateNumber,
    uint256 scoreNeeded
  ) external isChairman {
    require(currentState == VotingState.OPEN, "Vote is not open");
    require(
      candidateVoteOpenBlock[candidateNumber] + votingDeadline >= block.number,
      "Deadline not up"
    );

    // Calculate votes here
    if (candidateVoteScore[candidateNumber] >= scoreNeeded) {
      emit vote_results(
        "Accepted",
        candidateNumber,
        candidateVoteScore[candidateNumber],
        scoreNeeded
      );
    } else if (candidateVoteScore[candidateNumber] < scoreNeeded) {
      emit vote_results(
        "Not accepted",
        candidateNumber,
        candidateVoteScore[candidateNumber],
        scoreNeeded
      );
    }
    emit vote_close(candidateNumber, block.number);
  }

  function distributeFee() external payable {
    // Divide the application fee equally among all committee members
    uint256 val = applicationFee / committeeMembers.length;
    for (uint256 i = 0; i < committeeMembers.length; i++) {
      address payable recipient = address(uint160(committeeMembers[i]));
      recipient.transfer(val);
    }
  }

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
        committeeMembers[i] = committeeMembers[committeeMembers.length - 1];
        // Pop last element
        committeeMembers.pop();
      }
    }
  }

  function addCommitteeMember(address user) public isChairman {
    require(
      committeeMembers.length < committeeSize,
      "Max committee Members size"
    );
    committeeMembers.push(user);
    isCommitteeMember[user] = true;
    emit new_committee_member(user);
  }

  function changeChairman(address user) public isChairman {
    committeeChairman = user;
    emit new_chairman(user);
  }
}
