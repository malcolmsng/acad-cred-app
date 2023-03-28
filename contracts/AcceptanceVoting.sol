pragma solidity ^0.5.0;

contract AcceptanceVoting {
  enum VotingState {
    OPEN,
    CLOSED
  }

  //List of committee members, chairman is part of committee members
  address[] committeeMembers;

  // member address => true if exist
  mapping(address => bool) isCommitteeMember;

  // members => applicant => true if voted
  mapping(address => mapping(uint256 => bool)) hasVoted;

  // applicantId => applicant address
  mapping(uint256 => address) applicantAddress;

  // applicantId => applicant name
  mapping(uint256 => string) applicantName;

  // applicant => votes it got
  mapping(uint256 => uint256) applicantVoteScore;

  // applicant => voting status
  mapping(uint256 => VotingState) applicantVotingState;

  // applicant => vote open block number
  mapping(uint256 => uint256) applicantVoteOpenBlock;

  // applicant => vote result status
  mapping(uint256 => bool) isApproved;

  // applicant => voting ended
  mapping(uint256 => bool) isConcluded;

  // applicantId => hasPaid
  mapping(uint256 => bool) hasPaid;

  address[] membersVoted;

  // application fee in wei
  uint256 applicationFee;
  //Size of commitee
  //uint32 committeeSize;

  //Address of committee chariman
  address committeeChairman;

  // Deadline in terms of blocks (1 eth block roughly 12.13 minutes)
  // applicant => vote deadline for committee to vote for that applicant
  uint256 votingTimeframe;

  // applicant => voting state for that applicant
  mapping(uint256 => VotingState) currentState;

  //Events
  event new_chairman(address newChairman);
  event new_committee_member(address newCommitteeMember);
  event remove_committee_member(address committeeMember);
  //event new_committee_size(uint256 size);
  event voted(
    address committeeMember,
    uint256 applicantNumber,
    uint256 voteScore
  );
  event vote_open(uint256 applicantNumber, uint256 blockNumber);
  event vote_close(uint256 applicantNumber, uint256 blockNumber);
  event vote_results(
    string outcome,
    uint256 applicantNumber,
    uint256 applicantScore,
    uint256 scoreNeeded
  );

  // should the person who deploys the contract be the chairman?
  // or should we allocate the chairman
  constructor(uint256 fee, uint256 voteDuration) public {
    committeeChairman = msg.sender;
    applicationFee = fee;
    votingTimeframe = voteDuration;
    //addCommitteeMember(msg.sender);
  }

  modifier isChairman() {
    require(
      msg.sender == committeeChairman,
      "Only Chairman can call this function"
    );
    _;
  }

  function addApplicant(
    uint256 institutionID,
    address institutionAddress,
    string calldata institutionName
  ) external {
    applicantAddress[institutionID] = institutionAddress;
    applicantName[institutionID] = institutionName;
    applicantVoteScore[institutionID] = 0;
    applicantVotingState[institutionID] = VotingState.CLOSED;
  }

  function getApplicantName(
    uint256 applicantNumber
  ) external view returns (string memory) {
    return applicantName[applicantNumber];
  }

  function checkApproved(uint256 applicantNumber) external view returns (bool) {
    return isApproved[applicantNumber];
  }

  function checkConcluded(
    uint256 applicantNumber
  ) external view returns (bool) {
    return isConcluded[applicantNumber];
  }

  function vote(
    uint256 applicantNumber,
    bool hasPhyiscalPremise,
    bool hasWebPresence,
    bool hasResearch,
    bool hasAwards,
    bool hasStudentMarketing
  ) external {
    require(isCommitteeMember[msg.sender], "You are not a committee member");
    require(
      applicantVotingState[applicantNumber] == VotingState.OPEN,
      "Applicant is not open for voting"
    );
    hasVoted[msg.sender][applicantNumber] = true;

    // Do voting calculation
    uint256 vote_score = 0;
    if (hasPhyiscalPremise) {
      vote_score++;
    }
    if (hasWebPresence) {
      vote_score++;
    }
    if (hasResearch) {
      vote_score++;
    }
    if (hasAwards) {
      vote_score++;
    }
    if (hasStudentMarketing) {
      vote_score++;
    }

    // Add committee member vote score to total vote score
    applicantVoteScore[applicantNumber] += vote_score;

    emit voted(msg.sender, applicantNumber, vote_score);
  }

  function payFee(uint applicantNumber) public payable {
    require(msg.value / 1E18 >= applicationFee, "Application fee is 5 ETH ");
    hasPaid[applicantNumber] = true;
    // address(uint160(address(this))).transfer(msg.value);
  }

  function openVote(uint256 applicantNumber) external isChairman {
    require(
      applicantVotingState[applicantNumber] == VotingState.CLOSED,
      "Applicant already undergoing voting"
    );
    require(hasPaid[applicantNumber] == true, "Applicant has not paid fee");

    // Change voting state
    applicantVotingState[applicantNumber] = VotingState.OPEN;

    // Write vote open block
    applicantVoteOpenBlock[applicantNumber] = block.number;

    // Emit event
    emit vote_open(applicantNumber, block.number);
  }

  function closeVote(
    uint256 applicantNumber,
    uint256 scoreNeeded
  ) external isChairman {
    require(
      currentState[applicantNumber] == VotingState.OPEN,
      "Vote is not open"
    );
    require(
      applicantVoteOpenBlock[applicantNumber] + votingTimeframe <= block.number,
      "Deadline not up"
    );

    // Calculate votes here

    if (applicantVoteScore[applicantNumber] >= scoreNeeded) {
      isApproved[applicantNumber] = true;
      emit vote_results(
        "Accepted",
        applicantNumber,
        applicantVoteScore[applicantNumber],
        scoreNeeded
      );
      addCommitteeMember(applicantAddress[applicantNumber]);
    } else if (applicantVoteScore[applicantNumber] < scoreNeeded) {
      emit vote_results(
        "Not accepted",
        applicantNumber,
        applicantVoteScore[applicantNumber],
        scoreNeeded
      );
    }

    isConcluded[applicantNumber] = true;
    distributeFee(applicantNumber);

    emit vote_close(applicantNumber, block.number);
  }

  function distributeFee(uint256 applicantNumber) public payable {
    require(hasPaid[applicantNumber] == true, "Applicant has not paid fee");
    // Divide the application fee equally among all committee members
    // members => applicant => true if voted
    // mapping(address => mapping(uint256 => bool)) hasVoted;

    // address[] memory memberVoted;
    for (uint256 i = 0; i < committeeMembers.length; i++) {
      if (hasVoted[committeeMembers[i]][applicantNumber]) {
        membersVoted.push(committeeMembers[i]);
      }
    }
    // CANNOT TRANSFER ASNDHASDASIDHH
    uint256 val = applicationFee / membersVoted.length;
    for (uint256 j = 0; j < membersVoted.length; j++) {
      address payable recipient = address(uint160(membersVoted[j]));
      recipient.transfer(val);
    }
  }

  // getters
  function getCommitteeChairman() external view returns (address) {
    return committeeChairman;
  }

  function getContractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getvotingTimeframe() external view returns (uint256) {
    return votingTimeframe;
  }

  // will return the index of the voting state
  // i.e. VotingState.OPEN == 0
  function getVotingState(
    uint256 applicantNumber
  ) external view returns (VotingState) {
    return currentState[applicantNumber];
  }

  function getFee() public view returns (uint256) {
    return applicationFee;
  }

  function getDeadline() public view returns (uint256) {
    return votingTimeframe;
  }

  function getCommitteeMembers() public view returns (address[] memory) {
    return committeeMembers;
  }

  function changeDeadline(uint256 votingDuration) public isChairman {
    votingTimeframe = votingDuration;
  }

  function changeFee(uint256 fee) public isChairman {
    applicationFee = fee;
  }

  /*
  function changeCommitteeSize(uint32 size) public isChairman {
    committeeSize = size;
    emit new_committee_size(size);
  }
  */
  function removeCommitteeMember(address user) public isChairman {
    require(isCommitteeMember[user], "User is not a current committee Member");
    require(committeeMembers.length > 0, "Committee is empty");
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

    emit remove_committee_member(user);
  }

  function addCommitteeMember(address user) public isChairman {
    require(
      isCommitteeMember[user] != true,
      "User is already a current committee Member"
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
