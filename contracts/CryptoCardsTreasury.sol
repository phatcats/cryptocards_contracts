/**
 * Phat Cats - Crypto-Cards
 *  - https://crypto-cards.io
 *  - https://phatcats.co
 *
 * Copyright 2019 (c) Phat Cats, Inc.
 *
 * Contract Audits:
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
pragma solidity 0.5.2;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";


//
// NOTE on Ownable:
//   Owner Account is attached to a Multi-Sig wallet controlled by a minimum of 3 C-Level Executives.
//

contract CryptoCardsTreasury is Initializable, Ownable {
    //
    // Storage
    //
    // Contract Controller
    address internal _contractController;  // Points to CryptoCardsController Contract

    // In-house Escrow - 70%
    address payable internal _inHouseAccount;
    uint256 internal _inHouseEscrow_paid;
    uint256 internal _inHouseEscrow_unpaid;

    // Out-sourcing - 30% up to Pool Limit
    uint256 internal _outSourcePool_total;        // Payout Total Accumulated
    uint256 internal _outSourcePool_limit;        // Payout Maximum
    uint256 internal _outSourcePool_interval;     // Payout Interval
    uint256 internal _outSourcePool_unpaid;       // Amount left Unpaid
    uint256 internal _outSourcePool_paid;         // Amount Paid Out
    uint256 internal _outSourcePool_memberCount;
    uint256 internal _outSourcePool_percentOnDeposit;

    mapping(address => uint256) internal _outsourcedMembers_payoutIndex;
    mapping(address => uint256) internal _outsourcedMembers_limit;
    mapping(address => uint256) internal _outsourcedMembers_paid;

    // Referral Account Escrows
    mapping(address => uint256) internal _referrals_unpaid;
    mapping(address => uint256) internal _referrals_paid;

    //
    // Modifiers
    //
    modifier onlyController() {
        require(msg.sender == _contractController, "Action only allowed by Controller contract");
        _;
    }

    //
    // Initialize
    //
    function initialize(address owner) public initializer {
        Ownable.initialize(owner);

        _outSourcePool_limit = 500 ether;
        _outSourcePool_interval = 250 finney; // cannot change once live
        _outSourcePool_percentOnDeposit = 30; // As percentage of deposit
    }

    function setContractAddresses(
        address controller,
        address payable account
    ) public onlyOwner {
        require(controller != address(0), "Invalid controller address supplied");
        require(account != address(0), "Invalid treasury address supplied");

        _contractController = controller;
        _inHouseAccount = account;
    }

    function setContractController(address controller) public onlyOwner {
        require(controller != address(0), "Invalid address supplied");
        _contractController = controller;
    }

    function setInHouseAccount(address payable account) public onlyOwner {
        require(account != address(0), "Invalid address supplied");
        _inHouseAccount = account;
    }

    function getOutSourcePoolPercentOnDeposit() public view returns (uint256) {
        return _outSourcePool_percentOnDeposit;
    }

    function setOutSourcePoolPercentOnDeposit(uint256 percent) public onlyOwner {
        require(percent >= 0 && percent < 100, "percent must be between 0 and 99");
        _outSourcePool_percentOnDeposit = percent;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function addOutsourcedMember(address account, uint256 limit) public onlyOwner {
        require(_outsourcedMembers_limit[account] == 0, "Outsourced-Member already exists");

        updateOutsourcedMemberLimit(account, limit);
        _outsourcedMembers_payoutIndex[account] = getCurrentPayoutIndex();
    }

    function updateOutsourcedMemberLimit(address account, uint256 limitToAdd) public onlyOwner {
        require(account != address(0), "Invalid address supplied");
        require(limitToAdd > 0, "limitToAdd must be greater than zero");
        require(_outSourcePool_unpaid + _outSourcePool_paid + limitToAdd <= _outSourcePool_limit, "limitToAdd exceeds remaining pool limit");

        // New Member, or previously paid out and removed from memberCount
        if (_outsourcedMembers_paid[account] == _outsourcedMembers_limit[account]) {
            _outSourcePool_memberCount = _outSourcePool_memberCount + 1;
        }

        _outsourcedMembers_limit[account] = _outsourcedMembers_limit[account] + limitToAdd;
        _outSourcePool_unpaid = _outSourcePool_unpaid + limitToAdd;
    }

    //
    // In-house Escrow
    //

    function getPaidBalanceOfEscrow() public view returns (uint256) {
        return _inHouseEscrow_paid;
    }

    function getUnpaidBalanceOfEscrow() public view returns (uint256) {
        return _inHouseEscrow_unpaid;
    }

    function withdrawFromEscrow() public onlyOwner {
        require(_inHouseAccount != address(0), "Invalid address supplied");
        require(_inHouseEscrow_unpaid > 0, "Unpaid balance must be greater than zero");
        uint256 amount = _inHouseEscrow_unpaid;
        _inHouseEscrow_paid = _inHouseEscrow_paid + amount;
        _inHouseEscrow_unpaid = 0;
        _inHouseAccount.transfer(amount);
    }

    //
    // Referrals
    //

    function getPaidBalanceOfReferrer(address account) public view returns (uint256) {
        return _referrals_paid[account];
    }

    function getUnpaidBalanceOfReferrer(address account) public view returns (uint256) {
        return _referrals_unpaid[account];
    }

    function withdrawMyReferralBalance() public {
        _withdrawForReferrer(address(msg.sender));
    }

    function withdrawForReferrer(address payable account) public onlyController returns (uint256) {
        return _withdrawForReferrer(account);
    }

    //
    // Out-source Pool
    //

    function getCurrentPayoutIndex() public view returns (uint256) {
        return ((_outSourcePool_total - (_outSourcePool_total % _outSourcePool_interval)) / _outSourcePool_interval);
    }

    function getOutsourcedMemberCount() public view returns (uint256) {
        return _outSourcePool_memberCount;
    }

    function getOutsourcedPayoutLimit() public view returns (uint256) {
        return _outSourcePool_limit;
    }

    function setOutsourcedPayoutLimit(uint256 limit) public onlyOwner {
        require(limit > _outSourcePool_unpaid && limit > _outSourcePool_total, "limit must be set higher");
        _outSourcePool_limit = limit;
    }

    function getOutsourcedPayoutInterval() public view returns (uint256) {
        return _outSourcePool_interval;
    }

    function getTotalBalanceOfPool() public view returns (uint256) {
        return _outSourcePool_total;
    }

    function getPaidBalanceOfPool() public view returns (uint256) {
        return _outSourcePool_paid;
    }

    function getUnpaidBalanceOfPool() public view returns (uint256) {
        return _outSourcePool_unpaid;
    }

    function getPaidBalanceOfMember(address account) public view returns (uint256) {
        return _outsourcedMembers_paid[account];
    }

    function getUnpaidBalanceOfMember(address account) public view returns (uint256) {
        return _outsourcedMembers_limit[account] - _outsourcedMembers_paid[account];
    }

    function getAvailableBalanceOfMember(address account) public view returns (uint256) {
        uint256 currentPayoutIndex = getCurrentPayoutIndex();
        if (_outsourcedMembers_payoutIndex[account] == currentPayoutIndex) { return 0; }
        if (_outsourcedMembers_limit[account] == 0 || _outsourcedMembers_paid[account] == _outsourcedMembers_limit[account]) { return 0; }

        uint256 payoutMultiplier = currentPayoutIndex - _outsourcedMembers_payoutIndex[account];
        uint256 maxPayable = (_outSourcePool_interval * payoutMultiplier) / _outSourcePool_memberCount;
        uint256 remainingToBePaid = _outsourcedMembers_limit[account] - _outsourcedMembers_paid[account];
        return remainingToBePaid > maxPayable ? maxPayable : remainingToBePaid;
    }

    function withdrawMyMemberBalance() public {
        _withdrawForMember(address(msg.sender));
    }

    function withdrawForMember(address payable account) public onlyController returns (uint256) {
        return _withdrawForMember(account);
    }

    function getUnusedFundsInPool() public view returns (uint256) {
        uint256 payouts = (_outSourcePool_paid + _outSourcePool_unpaid);
        if (payouts > _outSourcePool_total) { return 0; }
        return _outSourcePool_total - payouts;
    }

    function transferUnusedFundsFromPool() public onlyOwner {
        uint256 unusedFunds = getUnusedFundsInPool();
        require(unusedFunds > 0, "Unused funds must be greater than zero");
        require(_outSourcePool_total - unusedFunds >= 0, "Unused funds exceeds pool total");

        // Remove from Outsource Pool
        _outSourcePool_total = _outSourcePool_total - unusedFunds;

        // Transfer to In-house Escrow
        _inHouseEscrow_unpaid = _inHouseEscrow_unpaid + unusedFunds;
    }

    //
    // Deposit
    //

    function deposit(uint256 _amountDeposited, uint256 _amountForReferrer, address _referrer) public onlyController payable {
        require(_amountDeposited == msg.value, "amountDeposited does not match amount received");
        require(_amountDeposited - _amountForReferrer >= 0, "Referral amount exceeds amountDeposited");

        // Referrals
        if (_referrer != address(0) && _amountForReferrer > 0) {
            _referrals_unpaid[_referrer] = _referrals_unpaid[_referrer] + _amountForReferrer;
            _amountDeposited = _amountDeposited - _amountForReferrer;
        }

        // Out-sourcing
        uint256 outsourcePortion = _amountDeposited * _outSourcePool_percentOnDeposit / 100;
        if (_outSourcePool_total < _outSourcePool_limit) {
            if (_outSourcePool_total + outsourcePortion > _outSourcePool_limit) {
                outsourcePortion = _outSourcePool_limit - _outSourcePool_total;
            }
            _outSourcePool_total = _outSourcePool_total + outsourcePortion;
            _amountDeposited = _amountDeposited - outsourcePortion;
        }

        // In-house
        _inHouseEscrow_unpaid = _inHouseEscrow_unpaid + _amountDeposited;
    }

    function _withdrawForReferrer(address payable account) internal returns (uint256) {
        require(account != address(0), "Invalid account address supplied");
        require(_referrals_unpaid[account] > 0, "Unpaid balance must be greater than zero");

        uint256 amount = _referrals_unpaid[account];
        _referrals_paid[account] = _referrals_paid[account] + amount;
        _referrals_unpaid[account] = 0;

        account.transfer(amount);
        return amount;
    }

    function _withdrawForMember(address payable account) internal returns (uint256) {
        require(account != address(0), "Invalid account address supplied");
        uint256 amountToPay = getAvailableBalanceOfMember(account);
        require(amountToPay > 0, "Amount to pay must be greater than zero");
        require(_outSourcePool_unpaid - amountToPay >= 0, "Amount to pay exceeds available funds in pool");

        _outSourcePool_paid = _outSourcePool_paid + amountToPay;
        _outSourcePool_unpaid = _outSourcePool_unpaid - amountToPay;

        _outsourcedMembers_paid[account] = _outsourcedMembers_paid[account] + amountToPay;
        _outsourcedMembers_payoutIndex[account] = getCurrentPayoutIndex();

        if (_outsourcedMembers_paid[account] == _outsourcedMembers_limit[account]) {
            // No more bounty to pay out, remove from memberCount
            require(_outSourcePool_memberCount - 1 >= 0, "Invalid member count");
            _outSourcePool_memberCount = _outSourcePool_memberCount - 1;
        }

        account.transfer(amountToPay);
        return amountToPay;
    }
}
