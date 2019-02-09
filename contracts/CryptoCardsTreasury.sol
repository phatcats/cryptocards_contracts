/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 *
 * Contract Audits:
 *   - SmartDEC International - https://smartcontracts.smartdec.net
 *   - Callisto Security Department - https://callisto.network/
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

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsTreasury is Initializable, Ownable {
    // Contract Controller
    address internal contractController;  // Points to CryptoCardsController Contract

    // In-house Escrow - 70%
    address internal inHouseAccount;
    uint256 internal inHouseEscrow_paid;
    uint256 internal inHouseEscrow_unpaid;

    // Out-sourcing - 30% up to Pool Limit
    uint256 internal outSourcePool_total;        // Payout Total Accumulated
    uint256 internal outSourcePool_limit;        // Payout Maximum
    uint256 internal outSourcePool_interval;     // Payout Interval
    uint256 internal outSourcePool_unpaid;       // Amount left Unpaid
    uint256 internal outSourcePool_paid;         // Amount Paid Out
    uint256 internal outSourcePool_memberCount;

    mapping(address => uint256) internal outsourcedMembers_payoutIndex;
    mapping(address => uint256) internal outsourcedMembers_limit;
    mapping(address => uint256) internal outsourcedMembers_paid;

    // Referral Account Escrows
    mapping(address => uint256) internal referrals_unpaid;
    mapping(address => uint256) internal referrals_paid;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyController() {
        require(msg.sender == contractController);
        _;
    }

    /**
     * @dev todo..
     */
    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        outSourcePool_limit = 500 ether;
        outSourcePool_interval = 1 ether; // cannot change once live
    }

    /**
     * @dev todo..
     */
    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0));
        contractController = _controller;
    }

    /**
     * @dev todo..
     */
    function setInHouseAccount(address _account) public onlyOwner {
        require(_account != address(0));
        inHouseAccount = _account;
    }

    /**
     * @dev todo..
     */
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev todo..
     */
    function addOutsourcedMember(address _account, uint256 _limit) public onlyOwner {
        updateOutsourcedMemberLimit(_account, _limit);

        outsourcedMembers_payoutIndex[_account] = getCurrentPayoutIndex();
        outSourcePool_memberCount = outSourcePool_memberCount + 1;
    }

    /**
     * @dev todo..
     */
    function updateOutsourcedMemberLimit(address _account, uint256 _limitToAdd) public onlyOwner {
        require(_account != address(0) && _limitToAdd > 0);
        require(outSourcePool_unpaid + outSourcePool_paid + _limitToAdd <= outSourcePool_limit);

        if (outsourcedMembers_paid[_account] == outsourcedMembers_limit[_account]) {
            // Previously paid out and removed from memberCount, let's add back now that member has a new limit
            outSourcePool_memberCount = outSourcePool_memberCount + 1;
        }

        outsourcedMembers_limit[_account] = outsourcedMembers_limit[_account] + _limitToAdd;
        outSourcePool_unpaid = outSourcePool_unpaid + _limitToAdd;
    }

    //
    // In-house Escrow
    //

    function getPaidBalanceOfEscrow() public view returns (uint256) {
        return inHouseEscrow_paid;
    }

    function getUnpaidBalanceOfEscrow() public view returns (uint256) {
        return inHouseEscrow_unpaid;
    }

    function withdrawFromEscrow() public onlyOwner {
        require(inHouseEscrow_unpaid > 0 && inHouseAccount != address(0));
        uint256 amount = inHouseEscrow_unpaid;
        inHouseEscrow_paid = inHouseEscrow_paid + amount;
        inHouseEscrow_unpaid = inHouseEscrow_unpaid - amount;
        inHouseAccount.transfer(amount);
    }

    //
    // Referrals
    //

    function getPaidBalanceOfReferrer(address _account) public view returns (uint256) {
        return referrals_paid[_account];
    }

    function getUnpaidBalanceOfReferrer(address _account) public view returns (uint256) {
        return referrals_unpaid[_account];
    }

    function withdrawForReferrer() public {
        require(msg.sender != address(0));
        require(referrals_unpaid[msg.sender] > 0);

        uint256 amount = referrals_unpaid[msg.sender];
        referrals_paid[msg.sender] = referrals_paid[msg.sender] + amount;
        referrals_unpaid[msg.sender] = referrals_unpaid[msg.sender] - amount;

        msg.sender.transfer(amount);
    }

    //
    // Out-source Pool
    //

    function getCurrentPayoutIndex() public view returns (uint256) {
        return ((outSourcePool_total - (outSourcePool_total % outSourcePool_interval)) / outSourcePool_interval);
    }

    function getOutsourcedMemberCount() public view returns (uint256) {
        return outSourcePool_memberCount;
    }

    function getOutsourcedPayoutLimit() public view returns (uint256) {
        return outSourcePool_limit;
    }

    function setOutsourcedPayoutLimit(uint256 _limit) public onlyOwner {
        require(_limit > outSourcePool_unpaid && _limit > outSourcePool_total);
        outSourcePool_limit = _limit;
    }

    function getOutsourcedPayoutInterval() public view returns (uint256) {
        return outSourcePool_interval;
    }

    function getTotalBalanceOfPool() public view returns (uint256) {
        return outSourcePool_total;
    }

    function getPaidBalanceOfPool() public view returns (uint256) {
        return outSourcePool_paid;
    }

    function getUnpaidBalanceOfPool() public view returns (uint256) {
        return outSourcePool_unpaid;
    }

    function getPaidBalanceOfMember(address _account) public view returns (uint256) {
        return outsourcedMembers_paid[_account];
    }

    function getUnpaidBalanceOfMember(address _account) public view returns (uint256) {
        return outsourcedMembers_limit[_account] - outsourcedMembers_paid[_account];
    }

    function getAvailableBalanceOfMember(address _account) public view returns (uint256) {
        uint256 currentPayoutIndex = getCurrentPayoutIndex();
        if (outsourcedMembers_payoutIndex[_account] == currentPayoutIndex) { return 0; }
        if (outsourcedMembers_limit[_account] == 0 || outsourcedMembers_paid[_account] == outsourcedMembers_limit[_account]) { return 0; }

        uint256 payoutMultiplier = currentPayoutIndex - outsourcedMembers_payoutIndex[_account];
        uint256 maxPayable = (outSourcePool_interval * payoutMultiplier) / outSourcePool_memberCount;
        uint256 remainingToBePaid = outsourcedMembers_limit[_account] - outsourcedMembers_paid[_account];
        return remainingToBePaid > maxPayable ? maxPayable : remainingToBePaid;
    }

    function withdrawForMember() public {
        address member = msg.sender;
        uint256 amountToPay = getAvailableBalanceOfMember(member);
        require(amountToPay > 0);
        require(outSourcePool_unpaid - amountToPay >= 0);

        outSourcePool_paid = outSourcePool_paid + amountToPay;
        outSourcePool_unpaid = outSourcePool_unpaid - amountToPay;

        outsourcedMembers_paid[member] = outsourcedMembers_paid[member] + amountToPay;
        outsourcedMembers_payoutIndex[member] = getCurrentPayoutIndex();

        if (outsourcedMembers_paid[member] == outsourcedMembers_limit[member]) {
            // No more bounty to pay out, remove from memberCount
            require(outSourcePool_memberCount - 1 >= 0);
            outSourcePool_memberCount = outSourcePool_memberCount - 1;
        }

        member.transfer(amountToPay);
    }

    function getUnusedFundsInPool() public view returns (uint256) {
        return outSourcePool_total - (outSourcePool_paid + outSourcePool_unpaid);
    }

    function transferUnusedFundsFromPool() public onlyOwner {
        uint256 unusedFunds = getUnusedFundsInPool();
        require(unusedFunds > 0);
        require(outSourcePool_total - unusedFunds >= 0);

        // Remove from Outsource Pool
        outSourcePool_total = outSourcePool_total - unusedFunds;

        // Transfer to In-house Escrow
        inHouseEscrow_unpaid = inHouseEscrow_unpaid + unusedFunds;
    }

    //
    // Deposit
    //

    /**
     * @dev todo..
     */
    function deposit(uint256 _amountDeposited, uint256 _amountForReferrer, address _referrer) public onlyController payable {
        require(_amountDeposited == msg.value);
        require(_amountDeposited - _amountForReferrer >= 0);

        // Referrals
        if (_referrer != address(0) && _amountForReferrer > 0) {
            referrals_unpaid[_referrer] = referrals_unpaid[_referrer] + _amountForReferrer;
            _amountDeposited = _amountDeposited - _amountForReferrer;
        }

        // Out-sourcing
        uint256 outsourcePortion = _amountDeposited / 30;
        if (outSourcePool_total < outSourcePool_limit) {
            if (outSourcePool_total + outsourcePortion > outSourcePool_limit) {
                outsourcePortion = outSourcePool_limit - outSourcePool_total;
            }
            outSourcePool_total = outSourcePool_total + outsourcePortion;
            _amountDeposited = _amountDeposited - outsourcePortion;
        }

        // In-house
        inHouseEscrow_unpaid = inHouseEscrow_unpaid + _amountDeposited;
    }
}
