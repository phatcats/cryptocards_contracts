/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2018 (c) Phat Cats, Inc.
 */
/*
    - when receiving funds:
        - referral amount to referrals

        - up to 30% to out-source pool

                if outSourcePool.total < outSourcePool.limit
                    amountToAdd = receivedFunds / 30
                    if outSourcePool.total + amountToAdd > outSourcePool.limit
                        amountToAdd = outSourcePool.limit - outSourcePool.total
                    outSourcePool.total += amountToAdd

        - remaining 70% or more to in-house accounts

    - when a member is added:
        currentPayoutIndex = ((outSourcePool.total - (outSourcePool.total % outSourcePool.interval)) / outSourcePool.interval)
        outsourcedMembers[address].payoutIndex = currentPayoutIndex
        outSourcePool.memberCount += 1

    - when a member limit is updated:
        if outSourcePool.unpaid + outSourcePool.paid + limitToAdd <= outSourcePool.limit
            outsourcedMembers[address].limit += limitToAdd
            outSourcePool.unpaid += limitToAdd

    - when a member requests payment:
        currentPayoutIndex = ((outSourcePool.total - (outSourcePool.total % outSourcePool.interval)) / outSourcePool.interval)
        if outsourcedMembers[address].payoutIndex < currentPayoutIndex && outsourcedMembers[address].paid < outsourcedMembers[address].limit

            payoutMultiplier = currentPayoutIndex - outsourcedMembers[address].payoutIndex
            maxPayable = (outSourcePool.interval * payoutMultiplier) / teamCounts.design

            remainingToBePaid = outsourcedMembers[address].limit - outsourcedMembers[address].paid
            amountToPay = remainingToBePaid > maxPayable ? maxPayable : remainingToBePaid

            outSourcePool.paid += amountToPay;
            outSourcePool.unpaid -= amountToPay;

            outsourcedMembers[address].paid += amountToPay
            outsourcedMembers[address].payoutIndex = currentPayoutIndex

    - when recovering unused pool funds:
        recoverableFunds = outSourcePool.total - (outSourcePool.paid + outSourcePool.unpaid)

*/
pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./pausable.sol";


contract CryptoCardsTreasury is Ownable {
    using SafeMath for uint256;

    modifier onlyController() {
        require(msg.sender == contractController);
        _;
    }

    struct AccountEscrow {
        uint256 unpaid;
        uint256 paid;
    }

    struct AccountPool {
        uint256 total;      // Payout Total Accumulated
        uint256 limit;      // Payout Maximum
        uint256 interval;   // Payout Interval
        uint256 unpaid;     // Amount left Unpaid
        uint256 paid;       // Amount Paid Out
        uint256 memberCount;
    }

    struct PayoutRecord {
        uint256 payoutIndex;
        uint256 limit;
        uint256 paid;
    }

    // In-house Escrow - 70%
    AccountEscrow private inHouseEscrow;
    address private inHouseAccount;

    // Out-sourcing - 30% up to Pool Limit
    AccountPool private outSourcePool;
    mapping(address => PayoutRecord) private outsourcedMembers;

    // Referral Account Escrows
    mapping(address => AccountEscrow) private referrals;

    // Contract Controller
    address internal contractController;  // Points to CryptoCardsController Contract

    constructor() public {
//        inHouseAccount = address(0x2C46170cE4436Ca1e19550228777F283c0923AdB); // Ganache Address 8 (index 7)
        outSourcePool.limit = 500 ether;
        outSourcePool.interval = 1 ether; // cannot change once live
    }

    function initialize(address _controller, address _account) public onlyOwner {
        contractController = _controller;
        inHouseAccount = _account;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setContractController(address _controller) public onlyOwner {
        contractController = _controller;
    }

    function setInHouseAccount(address _account) public onlyOwner {
        require(_account != address(0));
        inHouseAccount = _account;
    }

    function addOutsourcedMember(address _account, uint256 _limit) public onlyOwner {
        updateOutsourcedMemberLimit(_account, _limit);

        outsourcedMembers[_account].payoutIndex = getCurrentPayoutIndex();
        outSourcePool.memberCount = outSourcePool.memberCount + 1;
    }

    function updateOutsourcedMemberLimit(address _account, uint256 _limitToAdd) public onlyOwner {
        require(_account != address(0) && _limitToAdd > 0);
        require(outSourcePool.unpaid + outSourcePool.paid + _limitToAdd <= outSourcePool.limit);

        outsourcedMembers[_account].limit = outsourcedMembers[_account].limit.add(_limitToAdd);
        outSourcePool.unpaid = outSourcePool.unpaid.add(_limitToAdd);
    }

    //
    // In-house Escrow
    //

    function getPaidBalanceOfEscrow() public view returns (uint256) {
        return inHouseEscrow.paid;
    }

    function getUnpaidBalanceOfEscrow() public view returns (uint256) {
        return inHouseEscrow.unpaid;
    }

    function withdrawFromEscrow() public onlyOwner {
        require(inHouseEscrow.unpaid > 0 && inHouseAccount != address(0));
        uint256 amount = inHouseEscrow.unpaid;
        inHouseEscrow.paid = inHouseEscrow.paid.add(amount);
        inHouseEscrow.unpaid = inHouseEscrow.unpaid.sub(amount);
        inHouseAccount.transfer(amount);
    }

    //
    // Referrals
    //

    function getPaidBalanceOfReferrer(address _account) public view returns (uint256) {
        return referrals[_account].paid;
    }

    function getUnpaidBalanceOfReferrer(address _account) public view returns (uint256) {
        return referrals[_account].unpaid;
    }

    function withdrawForReferrer() public {
        require(msg.sender != address(0));
        require(referrals[msg.sender].unpaid > 0);

        uint256 amount = referrals[msg.sender].unpaid;
        referrals[msg.sender].paid = referrals[msg.sender].paid.add(amount);
        referrals[msg.sender].unpaid = referrals[msg.sender].unpaid.sub(amount);

        msg.sender.transfer(amount);
    }

    //
    // Out-source Pool
    //

    function getCurrentPayoutIndex() public view returns (uint256) {
        return ((outSourcePool.total - (outSourcePool.total % outSourcePool.interval)) / outSourcePool.interval);
    }

    function getOutsourcedMemberCount() public view returns (uint256) {
        return outSourcePool.memberCount;
    }

    function getOutsourcedPayoutLimit() public view returns (uint256) {
        return outSourcePool.limit;
    }

    function setOutsourcedPayoutLimit(uint256 _limit) public onlyOwner {
        require(_limit > outSourcePool.unpaid && _limit > outSourcePool.total);
        outSourcePool.limit = _limit;
    }

    function getOutsourcedPayoutInterval() public view returns (uint256) {
        return outSourcePool.interval;
    }

    function getTotalBalanceOfPool() public view returns (uint256) {
        return outSourcePool.total;
    }

    function getPaidBalanceOfPool() public view returns (uint256) {
        return outSourcePool.paid;
    }

    function getUnpaidBalanceOfPool() public view returns (uint256) {
        return outSourcePool.unpaid;
    }

    function getPaidBalanceOfMember(address _account) public view returns (uint256) {
        return outsourcedMembers[_account].paid;
    }

    function getUnpaidBalanceOfMember(address _account) public view returns (uint256) {
        return outsourcedMembers[_account].limit - outsourcedMembers[_account].paid;
    }

    function getAvailableBalanceOfMember(address _account) public view returns (uint256) {
        uint256 currentPayoutIndex = getCurrentPayoutIndex();
        if (outsourcedMembers[_account].payoutIndex == currentPayoutIndex) { return 0; }
        if (outsourcedMembers[_account].limit == 0 || outsourcedMembers[_account].paid == outsourcedMembers[_account].limit) { return 0; }

        uint256 payoutMultiplier = currentPayoutIndex - outsourcedMembers[_account].payoutIndex;
        uint256 maxPayable = (outSourcePool.interval * payoutMultiplier) / outSourcePool.memberCount;
        uint256 remainingToBePaid = outsourcedMembers[_account].limit - outsourcedMembers[_account].paid;
        return remainingToBePaid > maxPayable ? maxPayable : remainingToBePaid;
    }

    function withdrawForMember() public {
        uint256 amountToPay = getAvailableBalanceOfMember(msg.sender);
        require(amountToPay > 0);

        outSourcePool.paid = outSourcePool.paid.add(amountToPay);
        outSourcePool.unpaid = outSourcePool.unpaid.sub(amountToPay);

        outsourcedMembers[msg.sender].paid = outsourcedMembers[msg.sender].paid.add(amountToPay);
        outsourcedMembers[msg.sender].payoutIndex = getCurrentPayoutIndex();

        msg.sender.transfer(amountToPay);
    }

    function getUnusedFundsInPool() public view returns (uint256) {
        return outSourcePool.total - (outSourcePool.paid + outSourcePool.unpaid);
    }

    function transferUnusedFundsFromPool() public onlyOwner {
        uint256 unusedFunds = getUnusedFundsInPool();
        require(unusedFunds > 0);

        // Remove from Outsource Pool
        outSourcePool.total = outSourcePool.total.sub(unusedFunds);

        // Transfer to In-house Escrow
        inHouseEscrow.unpaid = inHouseEscrow.unpaid.add(unusedFunds);
    }

    //
    // Deposit
    //

    function deposit(uint256 _amountDeposited, uint256 _amountForReferrer, address _referrer) public onlyController payable {
        require(_amountDeposited == msg.value);

        // Referrals
        if (_referrer != address(0) && _amountForReferrer > 0) {
            referrals[_referrer].unpaid = referrals[_referrer].unpaid.add(_amountForReferrer);
            _amountDeposited = _amountDeposited.sub(_amountForReferrer);
        }

        // Out-sourcing
        uint256 outsourcePortion = _amountDeposited.div(30);
        if (outSourcePool.total < outSourcePool.limit) {
            if (outSourcePool.total + outsourcePortion > outSourcePool.limit) {
                outsourcePortion = outSourcePool.limit - outSourcePool.total;
            }
            outSourcePool.total = outSourcePool.total.add(outsourcePortion);
            _amountDeposited = _amountDeposited.sub(outsourcePortion);
        }

        // In-house
        inHouseEscrow.unpaid = inHouseEscrow.unpaid.add(_amountDeposited);
    }
}
