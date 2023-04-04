// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

  // address[] membersVoted;

  // application fee in wei
  uint256 applicationFee;
  //Size of commitee
  uint32 committeeSize;

  //Address of committee chariman
  address committeeChairman;

  // Deadline in terms of blocks (1 eth block roughly 12.13 minutes)
  // applicant => vote deadline for committee to vote for that applicant
  uint256 votingTimeframe;

  // applicant => voting state for that applicant
  //mapping(uint256 => VotingState) applicantVotingState;

  //Events
  event new_chairman(address newChairman);
  event new_committee_member(address newCommitteeMember, uint256 committeeSize);
  event remove_committee_member(address committeeMember, uint256 committeeSize);
  event new_committee_size(uint256 size);
  event applicant_paid(uint256 applicantNumber);
  event voted(
    address committeeMember,
    uint256 applicantNumber,
    uint256 voteScore
  );
  event vote_open(uint256 applicantNumber, uint256 blockNumber);
  event vote_close(uint256 applicantNumber, uint256 blockNumber);
  event vote_results_accepted(
    string outcome,
    uint256 applicantNumber,
    uint256 applicantScore,
    uint256 scoreNeeded
  );
  event vote_results_rejected(
    string outcome,
    uint256 applicantNumber,
    uint256 applicantScore,
    uint256 scoreNeeded
  );
  event distributed_fee(
    address votedMember,
    uint256 val,
    uint256 contract_balance,
    uint256 acc_balance
  );

  event testEvent();

  // should the person who deploys the contract be the chairman?
  // or should we allocate the chairman
  // committee max size 10 to begin with

  constructor(uint256 fee, uint256 voteDuration) {
    committeeChairman = msg.sender;
    committeeSize = 10;
    applicationFee = fee;
    votingTimeframe = voteDuration;
    addCommitteeMember(msg.sender);
  }

  modifier isChairman() {
    require(
      msg.sender == committeeChairman,
      "Only Chairman can call this function"
    );
    _;
  }

  function addApplicant(
    uint256 applicantNumber,
    address _applicantAddress,
    string calldata _applicantName
  ) external {
    applicantAddress[applicantNumber] = _applicantAddress;
    applicantName[applicantNumber] = _applicantName;
    applicantVoteScore[applicantNumber] = 0;
    applicantVotingState[applicantNumber] = VotingState.CLOSED;
  }

  function getApplicantName(
    uint256 applicantNumber
  ) public view returns (string memory) {
    return applicantName[applicantNumber];
  }

  function checkApproved(uint256 applicantNumber) public view returns (bool) {
    return isApproved[applicantNumber];
  }

  function checkConcluded(uint256 applicantNumber) public view returns (bool) {
    return isConcluded[applicantNumber];
  }

  function vote(
    uint256 applicantNumber,
    bool hasPhyiscalPremise,
    bool hasWebPresence,
    bool hasResearch,
    bool hasAwards,
    bool hasStudentMarketing
  ) public {
    require(isCommitteeMember[msg.sender], "You are not a committee member");
    require(
      applicantVotingState[applicantNumber] == VotingState.OPEN,
      "Applicant is not open for voting"
    );
    hasVoted[msg.sender][applicantNumber] = true;

    emit testEvent();
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

  function payFee(uint applicantNumber, address applicantAdd) public payable {
    require(msg.value / 1E18 >= applicationFee, "Application fee is 5 ETH");
    require(hasPaid[applicantNumber] == false, "Applicant fee has been paid");
    hasPaid[applicantNumber] = true;
    applicantVotingState[applicantNumber] = VotingState.CLOSED;
    applicantAddress[applicantNumber] = applicantAdd;
    //payable(committeeChairman).transfer(msg.value);
    emit applicant_paid(applicantNumber);
    //emit testEvent(msg.value / 1E16);
  }

  function openVote(uint256 applicantNumber) external isChairman {
    require(
      applicantVotingState[applicantNumber] == VotingState.CLOSED,
      "Applicant already undergoing voting"
    );
    // require(hasPaid[applicantNumber] == true, "Applicant has not paid fee");

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
  ) public isChairman {
    require(
      applicantVotingState[applicantNumber] == VotingState.OPEN,
      "Vote is not open"
    );
    require(
      applicantVoteOpenBlock[applicantNumber] + votingTimeframe <= block.number,
      "Deadline not up"
    );

    // Calculate votes here

    if (applicantVoteScore[applicantNumber] >= scoreNeeded) {
      isApproved[applicantNumber] = true;
      emit vote_results_accepted(
        "Accepted",
        applicantNumber,
        applicantVoteScore[applicantNumber],
        scoreNeeded
      );
      //addCommitteeMember(applicantAddress[applicantNumber]); ///figure out why not working
    } else if (applicantVoteScore[applicantNumber] < scoreNeeded) {
      isApproved[applicantNumber] = false;

      emit vote_results_rejected(
        "Not accepted",
        applicantNumber,
        applicantVoteScore[applicantNumber],
        scoreNeeded
      );
    }

    isConcluded[applicantNumber] = true;
    delete applicantAddress[applicantNumber];
    applicantVotingState[applicantNumber] = VotingState.CLOSED;
    distributeFee(applicantNumber);

    emit vote_close(applicantNumber, block.number);
  }

  function distributeFee(uint256 applicantNumber) public payable isChairman {
    require(hasPaid[applicantNumber] == true, "Applicant has not paid fee");
    require(isConcluded[applicantNumber] == true, "Voting has not concluded");
    // Divide the application fee equally among all committee members
    // members => applicant => true if voted
    // mapping(address => mapping(uint256 => bool)) hasVoted;
    // address[] memory memberVoted;
    uint256 membersVotedLength;
    for (uint256 i = 0; i < committeeMembers.length; i++) {
      if (hasVoted[committeeMembers[i]][applicantNumber]) {
        membersVotedLength++;
      }
    }
    uint256 val = (applicationFee * 1E18) / membersVotedLength;
    for (uint256 j = 0; j < committeeMembers.length; j++) {
      if (hasVoted[committeeMembers[j]][applicantNumber]) {
        address payable recipient = payable(committeeMembers[j]);
        recipient.transfer(val);
        emit distributed_fee(
          committeeMembers[j],
          val,
          address(this).balance,
          address(committeeMembers[j]).balance
        );
      }
    }
  }

  // getters
  function getCommitteeChairman() public view returns (address) {
    return committeeChairman;
  }

  // function getChairmanBalance() external view returns (uint256) {
  //   return address(this).balance;
  // }

  function getvotingTimeframe() external view returns (uint256) {
    return votingTimeframe;
  }

  // will return the index of the voting state
  // i.e. VotingState.OPEN == 0
  function getVotingState(
    uint256 applicantNumber
  ) public view returns (VotingState) {
    return applicantVotingState[applicantNumber];
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

  function getAmountOfCommitteeMembers() public view returns (uint256) {
    return committeeMembers.length;
  }

  function changeDeadline(uint256 votingDuration) public isChairman {
    votingTimeframe = votingDuration;
  }

  function changeFee(uint256 fee) public isChairman {
    applicationFee = fee;
  }

  function changeCommitteeSize(uint32 size) public isChairman {
    committeeSize = size;
    emit new_committee_size(size);
  }

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

    emit remove_committee_member(user, committeeMembers.length);
  }

  function addCommitteeMember(address user) public isChairman {
    require(
      committeeMembers.length < committeeSize,
      "Committee max size reached"
    );
    require(
      isCommitteeMember[user] != true,
      "User is already a current committee Member"
    );
    committeeMembers.push(user);
    isCommitteeMember[user] = true;
    emit new_committee_member(user, committeeMembers.length);
  }

  function changeChairman(address user) public isChairman {
    committeeChairman = user;
    emit new_chairman(user);
  }
}
