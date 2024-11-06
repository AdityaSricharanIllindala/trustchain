// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TrustChain {
    address payable public owner;
    uint8 public totalMembers = 2;
    uint8 public currMemberCount = 0;
    uint256 public individualDepositAmount = 0.01 ether;
    uint256 public surplus = 0.003 ether;
    uint256 public installmentInterval = 30 days;
    uint256 public defaultPenaltyPercentage = 10; // Penalty percentage for defaults

    struct Person {
        bool isMember;
        uint256 loanGranted;
        uint256 lastDepositedTime;
        uint256 totalDeposits;
        uint256 reputationScore;
        uint256 joinTime;
    }

    struct Loan {
        uint256 totalAmount;
        uint256 installmentAmount;
        uint16 installmentsPaid;
        uint16 totalInstallments;
        uint256 nextDueDate;
        bool isActive;
        uint256 lastPaymentDate; // Track the last payment date for default checks
        uint256 defaultCount; // Track the number of missed payments
    }

    mapping(address => Person) public members;
    mapping(address => Loan) public loans;

    event Deposited(address indexed member, uint256 amount);
    event LoanGranted(address indexed borrower, uint256 amount, uint256 reputation);
    event InstallmentPaid(address indexed borrower, uint256 amount, uint16 remainingInstallments);
    event LoanRepaidInFull(address indexed borrower, uint256 amount);
    event PenaltyApplied(address indexed borrower, uint256 penaltyAmount);
    event ReputationIncreased(address indexed borrower, uint256 newReputation);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyMember() {
        require(members[msg.sender].isMember, "Only members can perform this action.");
        _;
    }

    modifier canDeposit() {
        require(currMemberCount == totalMembers, "All members must join first.");
        _;
    }

    function joinFund() public {
        require(currMemberCount < totalMembers, "Maximum members reached.");
        require(!members[msg.sender].isMember, "Already a member.");
        
        members[msg.sender] = Person({
            isMember: true,
            loanGranted: 0,
            lastDepositedTime: block.timestamp,
            totalDeposits: 0,
            reputationScore: 1,
            joinTime: block.timestamp
        });
        currMemberCount++;
    }

    function deposit() public payable onlyMember canDeposit {
        require(msg.value == individualDepositAmount, "Incorrect deposit amount.");
        members[msg.sender].totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function requestLoan(uint256 amount) public onlyMember {
        require(amount > 0, "Loan amount must be greater than zero.");
        require(amount <= address(this).balance, "Insufficient funds in contract.");
        require(members[msg.sender].reputationScore > 0, "Reputation too low to request a loan.");

        // Grant loan in full if sufficient funds are available in the contract
        loans[msg.sender] = Loan({
            totalAmount: amount,
            installmentAmount: amount, 
            installmentsPaid: 0,
            totalInstallments: 1, 
            nextDueDate: block.timestamp + installmentInterval,
            isActive: true,
            lastPaymentDate: block.timestamp,
            defaultCount: 0
        });

        members[msg.sender].loanGranted += amount;
        payable(msg.sender).transfer(amount);

        emit LoanGranted(msg.sender, amount, members[msg.sender].reputationScore);
    }

    function payInstallment() public payable onlyMember {
        Loan storage loan = loans[msg.sender];
        require(loan.isActive, "No active loan found.");
        require(block.timestamp <= loan.nextDueDate, "Installment overdue.");
        require(msg.value == loan.installmentAmount, "Incorrect installment amount.");

        loan.lastPaymentDate = block.timestamp;
        loan.defaultCount = 0; // Reset default count on successful payment
        loan.installmentsPaid += 1;
        loan.nextDueDate += installmentInterval;

        // Increase reputation after proper repayment
        if (loan.installmentsPaid == loan.totalInstallments) {
            loan.isActive = false;
            members[msg.sender].loanGranted = 0; // Reset loan amount after full repayment
            members[msg.sender].reputationScore += 1; // Increase reputation score after full repayment

            emit LoanRepaidInFull(msg.sender, loan.totalAmount);
            emit ReputationIncreased(msg.sender, members[msg.sender].reputationScore);
        } else {
            emit InstallmentPaid(msg.sender, msg.value, loan.totalInstallments - loan.installmentsPaid);
        }
    }

    function checkMissedInstallments() public onlyMember {
        Loan storage loan = loans[msg.sender];

        if (loan.isActive) {
            if (block.timestamp > loan.nextDueDate) {
                loan.defaultCount += 1; // Increase default count
                uint256 missedPayments = loan.defaultCount;

                if (missedPayments > 1) {
                    uint256 penaltyAmount = (loan.totalAmount * defaultPenaltyPercentage) / 100;
                    loan.totalAmount += penaltyAmount; // Increase total amount by penalty
                    members[msg.sender].reputationScore = members[msg.sender].reputationScore > 1
                        ? members[msg.sender].reputationScore - 1
                        : 0;

                    emit PenaltyApplied(msg.sender, penaltyAmount);
                }

                loan.nextDueDate += installmentInterval; // Move due date to the next interval
            }
        }
    }

    function getLoanDetails(address borrower) public view returns (Loan memory) {
        return loans[borrower];
    }

    function withdrawSurplus() public onlyMember {
        require(loans[msg.sender].installmentsPaid == loans[msg.sender].totalInstallments, "Loan not fully repaid");
        require(address(this).balance >= surplus, "Insufficient balance for surplus withdrawal");

        payable(msg.sender).transfer(surplus);
    }

    // New function to check reputation score
    function getReputationScore() public view returns (uint256) {
        return members[msg.sender].reputationScore;
    }
}