// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract P2PChitFund {
  address payable public owner;
  uint8 public totalMembers = 2;
  uint8 public currMemberCount = 0;
  uint256 public individualDepositAmount = 0.01 ether;
  uint256 public surplus = 0.003 ether;
  uint256 public installmentInterval = 30 days;
  uint256 public defaultPenaltyPercentage = 10; // Penalty percentage for defaults
  uint256 public extendedDefaultThreshold = 2 * 30 days; // 2 missed installments threshold for penalty

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
  event LoanGranted(address indexed borrower, uint256 amount, uint256 reputation, bool isInstallmentPlan);
  event InstallmentPaid(address indexed borrower, uint256 amount, uint16 remainingInstallments);
  event LoanRepaidInFull(address indexed borrower, uint256 amount);
  event PenaltyApplied(address indexed borrower, uint256 penaltyAmount);

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

  function requestLoan(uint256 amount, uint16 totalInstallments) public onlyMember {
    require(amount > 0, "Loan amount must be greater than zero.");
    require(amount <= address(this).balance, "Insufficient funds in contract.");

    bool isInstallmentPlan = (amount > address(this).balance);

    if (isInstallmentPlan) {
      // Calculate installment amount if installments are required
      uint256 installmentAmount = amount / totalInstallments;

      loans[msg.sender] = Loan({
        totalAmount: amount,
        installmentAmount: installmentAmount,
        installmentsPaid: 0,
        totalInstallments: totalInstallments,
        nextDueDate: block.timestamp + installmentInterval,
        isActive: true,
        lastPaymentDate: block.timestamp, // Initialize last payment date
        defaultCount: 0 // Initialize default count
      });
    } else {
      loans[msg.sender] = Loan({
        totalAmount: amount,
        installmentAmount: amount, // Full repayment in one go
        installmentsPaid: 0,
        totalInstallments: 1,
        nextDueDate: block.timestamp + installmentInterval,
        isActive: true,
        lastPaymentDate: block.timestamp, // Initialize last payment date
        defaultCount: 0 // Initialize default count
      });
    }

    members[msg.sender].loanGranted += amount;
    payable(msg.sender).transfer(amount);

    emit LoanGranted(msg.sender, amount, members[msg.sender].reputationScore, isInstallmentPlan);
  }

  function payInstallment() public payable onlyMember {
    Loan storage loan = loans[msg.sender];
    require(loan.isActive, "No active loan found.");
    require(block.timestamp <= loan.nextDueDate, "Installment overdue.");
    require(msg.value == loan.installmentAmount, "Incorrect installment amount.");

    // Update the last payment date and reset default count on payment
    loan.lastPaymentDate = block.timestamp;
    loan.defaultCount = 0; // Reset default count on successful payment

    loan.installmentsPaid += 1;
    loan.nextDueDate += installmentInterval;

    if (loan.installmentsPaid == loan.totalInstallments) {
      loan.isActive = false;
      members[msg.sender].loanGranted = 0; // Reset loan amount after full repayment

      emit LoanRepaidInFull(msg.sender, loan.totalAmount);
    } else {
      emit InstallmentPaid(msg.sender, msg.value, loan.totalInstallments - loan.installmentsPaid);
    }
  }

  function checkMissedInstallments() public onlyMember {
    Loan storage loan = loans[msg.sender];

    // Only check if there is an active loan
    if (loan.isActive) {
      if (block.timestamp > loan.nextDueDate) {
        loan.defaultCount += 1; // Increase default count
        uint256 missedPayments = loan.defaultCount;

        // Apply penalty if missed payments exceed the threshold
        if (missedPayments > 1) { // Assuming 1 missed payment means 30 days
          uint256 penaltyAmount = (loan.totalAmount * defaultPenaltyPercentage) / 100;
          loan.totalAmount += penaltyAmount; // Increase total amount by penalty
          members[msg.sender].reputationScore = members[msg.sender].reputationScore > 1
            ? members[msg.sender].reputationScore - 1
            : 0;

          emit PenaltyApplied(msg.sender, penaltyAmount);
        }

        // Move due date to the next interval
        loan.nextDueDate += installmentInterval;
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
}