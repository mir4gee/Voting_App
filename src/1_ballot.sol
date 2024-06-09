//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol;

contract ballot {
    error AlreadyRegistered();
    error NotRegistered();
    error NotOwner();
    error NotCandidate();
    error NotVoter();
    error AlreadyVoted();
    error NoVotesCasted();
    error RegistrationOpen();
    error VotingOpen();
    error EndedState();
    struct voter {
        bool voted;
        address vote;
        address voterAddress;
    }

    struct candidate {
        uint VoteCount;
        address CandidateId;
    }

    enum State {
        Registration,
        Voting,
        Ended
    }

    uint256 private constant REG_TIME = 1 days;
    uint256 private constant VOT_TIME = 1 days;
    mapping(address => candidate) s_candidateList;
    mapping(address => voter) s_voterList;
    address[] private s_candidate_List;
    address[] private s_voter_List;
    address private owner;
    address private winner;
    uint private totalCandidates;
    uint private totalVoters;
    uint private totalVotesCasted;
    uint256 public registrationStartTime;
    uint256 public votingStartTime;
    State private state;

    event VoterRegistered(address voter);
    event CandidateAdded(address candidateId);
    event StateChanged(State newState);
    event Voted(address voter, address candidateId);
    event Winner(address Winner);

    constructor() {
        owner = msg.sender;
        totalCandidates = 0;
        totalVoters = 0;
        totalVotesCasted = 0;
        state = State.Registration;
        registrationStartTime = block.timestamp;
    }

    modifier checkOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    function registerAsVoter() public inState(State.Registration) {
        if (s_voterList[msg.sender].voterAddress != address(0)) {
            revert AlreadyRegistered();
        }
        s_voterList[msg.sender].voterAddress = msg.sender;
        s_voter_List.push(msg.sender);
        totalVoters++;
        emit VoterRegistered(msg.sender);
    }

    function registerAsCandidate() public inState(State.Registration) {
        if (s_candidateList[msg.sender].CandidateId != address(0)) {
            revert AlreadyRegistered();
        }
        s_candidateList[msg.sender].CandidateId = msg.sender;
        s_candidate_List.push(msg.sender);
        totalCandidates++;
        emit CandidateAdded(msg.sender);
    }

    function startVoting() public checkOwner inState(State.Registration){
        require(
            block.timestamp >= registrationStartTime + REG_TIME,
            "Registration period not over"
        );
        state = State.Voting;
        votingStartTime = block.timestamp;
        emit StateChanged(state);
    }

    function endVoting() public checkOwner inState(State.Voting){
        require(
            block.timestamp >= votingStartTime + VOT_TIME,
            "Voting period not over"
        );
        state = State.Ended;
        emit StateChanged(state);
    }

    function vote(address _candidateId) public inState(State.Voting){
        if (s_voterList[msg.sender].voterAddress == address(0)) {
            revert NotVoter();
        }
        if (s_voterList[msg.sender].voted == true) {
            revert AlreadyVoted();
        }
        if (s_candidateList[_candidateId].CandidateId != address(0)) {
            revert NotCandidate();
        }
        s_voterList[msg.sender].voted = true;
        s_voterList[msg.sender].vote = _candidateId;
        totalVotesCasted++;
        s_candidateList[_candidateId].VoteCount++;
        emit Voted(msg.sender, _candidateId);
    }

    function calculateWinner() public checkOwner inState(State.Ended) {
        if (totalVotesCasted == 0) {
            revert NoVotesCasted();
        }
        uint maxVotes = 0;
        for (uint i = 0; i < s_candidate_List.length; i++) {
            if (s_candidateList[s_candidate_List[i]].VoteCount > maxVotes) {
                maxVotes = s_candidateList[s_candidate_List[i]].VoteCount;
                winner = s_candidateList[s_candidate_List[i]].CandidateId;
            }
        }
        getWinnerCandidate();
        emit Winner(winner);
    }

    function reset() public checkOwner inState(State.Ended) {
        for (uint i = 0; i < s_voter_List.length; i++) {
            delete s_voterList[s_voter_List[i]];
        }
        for (uint i = 0; i < s_voter_List.length; i++) {
            delete s_candidateList[s_voter_List[i]];
        }
        totalCandidates = 0;
        totalVoters = 0;
        totalVotesCasted = 0;
        state = State.Registration;
        s_voter_List= new address[](0);
        s_candidate_List = new address[](0);
    }

    /** Getter Functions */

    function getVoterList() public view checkOwner returns (address[] memory) {
        return s_voter_List;
    }

    function getCandidateList()
        public
        view
        checkOwner
        returns (address[] memory)
    {
        return s_candidate_List;
    }

    function getWinnerCandidate() public view checkOwner inState(State.Ended) returns (address) {
        return winner;
    }

    function getVoterCount() public view returns (uint) {
        return totalVoters;
    }

    function getCandidateCount() public view returns (uint) {
        return totalCandidates;
    }

    function getVotesCasted() public view inState(State.Ended) returns (uint) {
        return totalVotesCasted;
    }

    function getVoterInfo(
        address _voterAddress
    ) public view returns (bool, address) {
        if (s_voterList[_voterAddress].voterAddress == address(0)) {
            revert NotVoter();
        }
        return (
            (
                s_voterList[_voterAddress].voted,
                s_voterList[_voterAddress].voterAddress
            )
        );
    }

    function getCandidateInfo(
        address _candidateAddress
    ) public view returns (uint, address) {
        if (s_candidateList[_candidateAddress].CandidateId == address(0)) {
            revert NotCandidate();
        }
        return (
            (
                s_candidateList[_candidateAddress].VoteCount,
                s_candidateList[_candidateAddress].CandidateId
            )
        );
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        if (
            state == State.Registration &&
            block.timestamp >= registrationStartTime + REG_TIME
        ) {
            upkeepNeeded = true;
        } else if (
            state == State.Voting &&
            block.timestamp >= votingStartTime + VOT_TIME
        ) {
            upkeepNeeded = true;
        } else {
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (
            state == State.Registration &&
            block.timestamp >= registrationStartTime + REG_TIME
        ) {
            startVoting();
        } else if (
            state == State.Voting &&
            block.timestamp >= votingStartTime + VOT_TIME
        ) {
            endVoting();
        }
    }
}

/*
    // modifier checkVoter() {
    //     if (s_voterList[msg.sender].voterAddress == address(0)) {
    //         revert NotRegistered();
    //     }
    //     _;
    // }

    // modifier checkCandidate() {
    //     if (s_candidateList[msg.sender].CandidateId != address(0)) {
    //         revert NotRegistered();
    //     }
    //     _;
    // }
    */

/*
    // function withdrawCandidate() public checkRegistrationOpen checkCandidate {
    //     delete s_candidateList[msg.sender];
    //     // deletes deletes mapping but doesnot do that with the array
    //     // it makes a gap in array
    //     totalCandidates--;
    //     for (uint i = 0; i < s_candidate_List.length; i++) {
    //         if (s_candidate_List[i] == msg.sender) {
    //             for (uint j = i; j < s_candidate_List.length - 1; j++) {
    //                 s_candidate_List[j] = s_candidate_List[j + 1];
    //             }
    //             s_candidate_List.pop();
    //             break;
    //         }
    //     }
    // }

    // function withdrawVoter() public checkRegistrationOpen checkVoter {
    //     delete s_voterList[msg.sender];
    //     totalVoters--;
    //     for (uint i = 0; i < s_voter_List.length; i++) {
    //         if (s_voter_List[i] == msg.sender) {
    //             for (uint j = i; j < s_voter_List.length - 1; j++) {
    //                 s_voter_List[j] = s_voter_List[j + 1];
    //             }
    //             s_voter_List.pop();
    //             break;
    //         }
    //     }
    // }
    */
