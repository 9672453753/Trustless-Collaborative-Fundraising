// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustlessCollaborativeFundraising {
    address public owner;
    uint public goalAmount;
    uint public deadline;
    uint public totalContributed;
    bool public goalReached;
    bool public fundsDistributed;

    struct Contributor {
        uint amount;
        bool refunded;
    }

    mapping(address => Contributor) public contributors;
    address[] public contributorList;

    event ContributionReceived(address indexed contributor, uint amount);
    event GoalReached(uint totalAmount);
    event RefundIssued(address indexed contributor, uint amount);
    event FundsDistributed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Deadline has passed");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Deadline not reached yet");
        _;
    }

    constructor(uint _goalAmount, uint _durationInDays) {
        owner = msg.sender;
        goalAmount = _goalAmount;
        deadline = block.timestamp + (_durationInDays * 1 days);
    }

    function contribute() external payable beforeDeadline {
        require(msg.value > 0, "Contribution must be greater than 0");

        if (contributors[msg.sender].amount == 0) {
            contributorList.push(msg.sender);
        }

        contributors[msg.sender].amount += msg.value;
        totalContributed += msg.value;

        emit ContributionReceived(msg.sender, msg.value);

        if (totalContributed >= goalAmount && !goalReached) {
            goalReached = true;
            emit GoalReached(totalContributed);
        }
    }

    function distributeFunds(address payable _recipient) external onlyOwner afterDeadline {
        require(goalReached, "Funding goal not reached");
        require(!fundsDistributed, "Funds already distributed");

        fundsDistributed = true;
        _recipient.transfer(address(this).balance);

        emit FundsDistributed();
    }

    function requestRefund() external afterDeadline {
        require(!goalReached, "Funding goal was reached, cannot refund");

        Contributor storage contributor = contributors[msg.sender];
        require(contributor.amount > 0, "No contributions found");
        require(!contributor.refunded, "Already refunded");

        contributor.refunded = true;
        payable(msg.sender).transfer(contributor.amount);

        emit RefundIssued(msg.sender, contributor.amount);
    }

    function getContributors() external view returns (address[] memory) {
        return contributorList;
    }
}
