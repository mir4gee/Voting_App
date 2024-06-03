//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ballot {
    struct voter {
        bool voted;
        address vote;
        address voterAddress;
    }

    struct candidate {
        uint VoteCount;
        address CandidateId;
    }

    // candidate[] s_candidateList;
    // voter[] s_voterList;
    mapping(address => candidate) candidateList;
    mapping(address => voter) voterList;
    address[] private candidate_List;
    address[] private voter_List;
    address private owner;
    address private winner;
    uint public totalCandidates;
    uint public totalVoters;
    uint public totalVotesCasted;
    bool public isVotingOpen;
    bool public isRegistrationOpen;

    constructor() {
        owner = msg.sender;
        totalCandidates = 0;
        totalVoters = 0;
        totalVotesCasted = 0;
        isVotingOpen = false;
        isRegistrationOpen = true;
    }

    function openVoting() public checkOwner {
        isVotingOpen = true;
        isRegistrationOpen = false;
    }

    function openRegistration() public checkOwner {
        isRegistrationOpen = true;
        isVotingOpen = false;
    }

    function closeVoting() public checkOwner {
        isVotingOpen = false;
    }

    modifier checkVoter() {
        require(
            voterList[msg.sender].voterAddress != address(0),
            "You are not registered as a voter"
        );
        _;
    }

    modifier checkCandidate() {
        require(
            candidateList[msg.sender].CandidateId != address(0),
            "You are not registered as a candidate"
        );
        _;
    }

    modifier checkOwner() {
        require(msg.sender == owner, "You are not the owner of the contract");
        _;
    }

    modifier checkVotingOpen() {
        require(isVotingOpen == true, "Voting is not open");
        _;
    }

    modifier checkRegistrationOpen() {
        require(isRegistrationOpen == true, "Registration is not open");
        _;
    }

    function registerAsVoter() public checkRegistrationOpen {
        require(
            voterList[msg.sender].voterAddress == address(0),
            "You are already registered as a voter"
        );
        // If the voter is not registered, then register the voter
        // address(0) means that the voter is not registered
        voterList[msg.sender].voterAddress = msg.sender;
        voter_List.push(msg.sender);
        totalVoters++;
    }

    function registerAsCandidate() public checkRegistrationOpen {
        require(
            candidateList[msg.sender].CandidateId == address(0),
            "You are already registered as a voter"
        );
        candidateList[msg.sender].CandidateId = msg.sender;
        candidate_List.push(msg.sender);
        totalCandidates++;
    }

    function voterInfo(
        address _voterAddress
    ) public view returns (bool, address) {
        require(
            voterList[_voterAddress].voterAddress != address(0),
            "You are not registered as a voter"
        );
        return (
            (
                voterList[_voterAddress].voted,
                voterList[_voterAddress].voterAddress
            )
        );
    }

    function candidateInfo(
        address _candidateAddress
    ) public view returns (uint, address) {
        require(
            candidateList[_candidateAddress].CandidateId != address(0),
            "You are not registered as a candidate"
        );
        return (
            (
                candidateList[_candidateAddress].VoteCount,
                candidateList[_candidateAddress].CandidateId
            )
        );
    }

    function withdrawCandidate() public checkRegistrationOpen checkCandidate {
        delete candidateList[msg.sender];
        // deletes deletes mapping but doesnot do that with the array
        // it makes a gap in array
        totalCandidates--;
        for (uint i = 0; i < candidate_List.length; i++) {
            if (candidate_List[i] == msg.sender) {
                for (uint j = i; j < candidate_List.length - 1; j++) {
                    candidate_List[j] = candidate_List[j + 1];
                }
                candidate_List.pop();
                break;
            }
        }
    }

    function withdrawVoter() public checkRegistrationOpen checkVoter {
        delete voterList[msg.sender];
        totalVoters--;
        for (uint i = 0; i < voter_List.length; i++) {
            if (voter_List[i] == msg.sender) {
                for (uint j = i; j < voter_List.length - 1; j++) {
                    voter_List[j] = voter_List[j + 1];
                }
                voter_List.pop();
                break;
            }
        }
    }

    function getwinnerCandidate() public view checkOwner returns (address) {
        return winner;
    }

    function vote(address _candidateId) public checkVotingOpen checkVoter {
        require(
            candidateList[_candidateId].CandidateId != address(0),
            "He/She is not registered as a candidate"
        );
        require(
            voterList[msg.sender].voted != true,
            "You have already voted for a candidate"
        );
        voterList[msg.sender].voted = true;
        voterList[msg.sender].vote = _candidateId;
        totalVotesCasted++;
        candidateList[_candidateId].VoteCount++;
    }

    function calculateWinner() public checkOwner {
        require(isRegistrationOpen == false, "Registration is still open");
        require(isVotingOpen == false, "Voting is still open");
        require(totalVotesCasted > 0, "No votes have been casted yet");
        uint maxVotes = 0;
        for (uint i = 0; i < candidate_List.length; i++) {
            if (candidateList[candidate_List[i]].VoteCount > maxVotes) {
                maxVotes = candidateList[candidate_List[i]].VoteCount;
                winner = candidateList[candidate_List[i]].CandidateId;
            }
        }
    }

    function reset() public checkOwner {
        for (uint i = 0; i < voter_List.length; i++) {
            delete voterList[voter_List[i]];
        }
        for (uint i = 0; i < voter_List.length; i++) {
            delete candidateList[voter_List[i]];
        }
        totalCandidates = 0;
        totalVoters = 0;
        totalVotesCasted = 0;
        openRegistration();
        delete voter_List;
        delete candidate_List;
    }

    function getVoterList() public view returns (address[] memory) {
        return voter_List;
    }

    function getCandidateList() public view returns (address[] memory) {
        return candidate_List;
    }
}
