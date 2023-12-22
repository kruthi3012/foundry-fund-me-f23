// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from '../../script/DeployFundMe.s.sol';

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr('user');
    uint256 public constant SEND_VALUE= 0.1 ether;
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        //deal is a foundry cheatcode to set the balance of an address
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public{
        vm.expectRevert(); //expects the next line to revert == assertEq(txn fails)
        fundMe.fund(); // sending 0 ETH instead of anything above 5
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundDataStructure() public funded{
        // vm.prank(USER); // next transaction is sent by user
        // fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFundAddsToArrayOfFunders() public funded{
        // vm.prank(USER);
        // fundMe.fund{value:SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER); //expectRevert ignores this line as it is not a transaction (vm. is ignored)
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded{
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance= address(fundMe).balance;
 
        //act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart-gasEnd)*tx.gasprice; 

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance+startingFundMeBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i=startingFunderIndex; i<numberOfFunders; i++){
            //ARRANGE
            // vm.prank(addr);
            // vm.deal(addr);
            // vm.hoax - combines both prank and deal together to fund a new address with eth
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        //ACT
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //everything between startPrank and stopPrank will be performed 
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for(uint160 i=startingFunderIndex; i<numberOfFunders; i++){
            //ARRANGE
            // vm.prank(addr);
            // vm.deal(addr);
            // vm.hoax - combines both prank and deal together to fund a new address with eth
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        //ACT
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //everything between startPrank and stopPrank will be performed 
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance+startingOwnerBalance == fundMe.getOwner().balance);
    }

}

// What can we do to work with addresses outside our system?
// 1. Unit - testing specific part of our code
// 2. Integration - testing how our code works with other parts of our code
// 3. Forked - testing our code on a simulated real environment
// 4. Staging - testing our code in a real env that is not prod
