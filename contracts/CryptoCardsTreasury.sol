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
    uint256 internal outSourcePool_percentOnDeposit;

    mapping(address => uint256) internal outsourcedMembers_payoutIndex;
    mapping(address => uint256) internal outsourcedMembers_limit;
    mapping(address => uint256) internal outsourcedMembers_paid;

    // Referral Account Escrows
    mapping(address => uint256) internal referrals_unpaid;
    mapping(address => uint256) internal referrals_paid;

    modifier onlyController() {
        require(msg.sender == contractController, "Action only allowed by Controller contract");
        _;
    }

    function initialize(address _owner) public initializer {
        Ownable.initialize(_owner);

        outSourcePool_limit = 500 ether;
        outSourcePool_interval = 250 finney; // cannot change once live
        outSourcePool_percentOnDeposit = 30; // As percentage of deposit
    }

    function setContractAddresses(
        address _controller,
        address _account
    ) public onlyOwner {
        require(_controller != address(0), "Invalid controller address supplied");
        require(_account != address(0), "Invalid treasury address supplied");

        contractController = _controller;
        inHouseAccount = _account;
    }

    function setContractController(address _controller) public onlyOwner {
        require(_controller != address(0), "Invalid address supplied");
        contractController = _controller;
    }

    function setInHouseAccount(address _account) public onlyOwner {
        require(_account != address(0), "Invalid address supplied");
        inHouseAccount = _account;
    }

    function getOutSourcePoolPercentOnDeposit() public view returns (uint256) {
        return outSourcePool_percentOnDeposit;
    }

    function setOutSourcePoolPercentOnDeposit(uint256 _percent) public onlyOwner {
        require(_percent >= 0 && _percent < 100, "percent must be between 0 and 99");
        outSourcePool_percentOnDeposit = _percent;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function addOutsourcedMember(address _account, uint256 _limit) public onlyOwner {
        require(outsourcedMembers_limit[_account] == 0, "Outsourced-Member already exists");

        updateOutsourcedMemberLimit(_account, _limit);
        outsourcedMembers_payoutIndex[_account] = getCurrentPayoutIndex();
    }

    function updateOutsourcedMemberLimit(address _account, uint256 _limitToAdd) public onlyOwner {
        require(_account != address(0), "Invalid address supplied");
        require(_limitToAdd > 0, "limitToAdd must be greater than zero");
        require(outSourcePool_unpaid + outSourcePool_paid + _limitToAdd <= outSourcePool_limit, "limitToAdd exceeds remaining pool limit");

        // New Member, or previously paid out and removed from memberCount
        if (outsourcedMembers_paid[_account] == outsourcedMembers_limit[_account]) {
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
        require(inHouseAccount != address(0), "Invalid address supplied");
        require(inHouseEscrow_unpaid > 0, "Unpaid balance must be greater than zero");
        uint256 amount = inHouseEscrow_unpaid;
        inHouseEscrow_paid = inHouseEscrow_paid + amount;
        inHouseEscrow_unpaid = 0;
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

    function withdrawMyReferralBalance() public {
        _withdrawForReferrer(address(msg.sender));
    }

    function withdrawForReferrer(address _account) public onlyController returns (uint256) {
        return _withdrawForReferrer(_account);
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
        require(_limit > outSourcePool_unpaid && _limit > outSourcePool_total, "limit must be set higher");
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

    function withdrawMyMemberBalance() public {
        _withdrawForMember(address(msg.sender));
    }

    function withdrawForMember(address _account) public onlyController returns (uint256) {
        return _withdrawForMember(_account);
    }

    function getUnusedFundsInPool() public view returns (uint256) {
        uint256 payouts = (outSourcePool_paid + outSourcePool_unpaid);
        if (payouts > outSourcePool_total) { return 0; }
        return outSourcePool_total - payouts;
    }

    function transferUnusedFundsFromPool() public onlyOwner {
        uint256 unusedFunds = getUnusedFundsInPool();
        require(unusedFunds > 0, "Unused funds must be greater than zero");
        require(outSourcePool_total - unusedFunds >= 0, "Unused funds exceeds pool total");

        // Remove from Outsource Pool
        outSourcePool_total = outSourcePool_total - unusedFunds;

        // Transfer to In-house Escrow
        inHouseEscrow_unpaid = inHouseEscrow_unpaid + unusedFunds;
    }

    //
    // Deposit
    //

    function deposit(uint256 _amountDeposited, uint256 _amountForReferrer, address _referrer) public onlyController payable {
        require(_amountDeposited == msg.value, "amountDeposited does not match amount received");
        require(_amountDeposited - _amountForReferrer >= 0, "Referral amount exceeds amountDeposited");

        // Referrals
        if (_referrer != address(0) && _amountForReferrer > 0) {
            referrals_unpaid[_referrer] = referrals_unpaid[_referrer] + _amountForReferrer;
            _amountDeposited = _amountDeposited - _amountForReferrer;
        }

        // Out-sourcing
        uint256 outsourcePortion = _amountDeposited * outSourcePool_percentOnDeposit / 100;
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

    function _withdrawForReferrer(address _account) internal returns (uint256) {
        require(_account != address(0), "Invalid account address supplied");
        require(referrals_unpaid[_account] > 0, "Unpaid balance must be greater than zero");

        uint256 amount = referrals_unpaid[_account];
        referrals_paid[_account] = referrals_paid[_account] + amount;
        referrals_unpaid[_account] = 0;

        _account.transfer(amount);
        return amount;
    }

    function _withdrawForMember(address _account) internal returns (uint256) {
        require(_account != address(0), "Invalid account address supplied");
        uint256 amountToPay = getAvailableBalanceOfMember(_account);
        require(amountToPay > 0, "Amount to pay must be greater than zero");
        require(outSourcePool_unpaid - amountToPay >= 0, "Amount to pay exceeds available funds in pool");

        outSourcePool_paid = outSourcePool_paid + amountToPay;
        outSourcePool_unpaid = outSourcePool_unpaid - amountToPay;

        outsourcedMembers_paid[_account] = outsourcedMembers_paid[_account] + amountToPay;
        outsourcedMembers_payoutIndex[_account] = getCurrentPayoutIndex();

        if (outsourcedMembers_paid[_account] == outsourcedMembers_limit[_account]) {
            // No more bounty to pay out, remove from memberCount
            require(outSourcePool_memberCount - 1 >= 0, "Invalid member count");
            outSourcePool_memberCount = outSourcePool_memberCount - 1;
        }

        _account.transfer(amountToPay);
        return amountToPay;
    }
}
