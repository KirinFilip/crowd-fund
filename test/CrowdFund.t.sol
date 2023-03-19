// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CrowdFund} from "../src/CrowdFund.sol";
import {MyERC20} from "../src/MyERC20.sol";

contract Constructor is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;

    function setUp() public {
        token = new MyERC20();
    }

    function test_CrowdFundConstructor() public {
        crowdFund = new CrowdFund(address(token));
        assertEq(address(crowdFund.token()), address(token));
    }
}

contract LaunchCampaign is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));
    }

    function test_LaunchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp),
            uint32(block.timestamp) + 7 days
        );

        (
            address creator,
            uint256 goal,
            uint256 pledged,
            uint32 startAt,
            uint32 endAt,
            bool isClaimed
        ) = crowdFund.campaigns(1);

        assertEq(creator, address(this));
        assertEq(goal, 1000);
        assertEq(pledged, 0);
        assertEq(startAt, uint32(block.timestamp));
        assertEq(endAt, uint32(block.timestamp) + 7 days);
        assertEq(isClaimed, false);
    }

    function test_RevertIfStartAtInThePast() public {
        vm.expectRevert("start at < now");
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) - 1,
            uint32(block.timestamp) + 7 days
        );
    }

    function test_RevertIfEndAtLessThanStartAt() public {
        vm.expectRevert("end at < start at");
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp),
            uint32(block.timestamp) - 1
        );
    }

    function test_RevertIfEndAtGreaterThanMaxDuration() public {
        vm.expectRevert("end at > max duration");
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp),
            uint32(block.timestamp) + 91 days
        );
    }
}

contract CancelCampaign is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;
    address alice = vm.addr(1);

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));

        vm.label(alice, "Alice");
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) + 1 days, // start in 1 day from now
            uint32(block.timestamp) + 7 days // end in 7 days from now
        );
    }

    function test_CancelCampaign() public {
        launchCampaign();
        crowdFund.cancelCampaign(1);
        (
            address creator,
            uint256 goal,
            uint256 pledged,
            uint32 startAt,
            uint32 endAt,
            bool isClaimed
        ) = crowdFund.campaigns(1);

        assertEq(creator, address(0));
        assertEq(goal, 0);
        assertEq(pledged, 0);
        assertEq(startAt, 0);
        assertEq(endAt, 0);
        assertEq(isClaimed, false);
    }

    function test_RevertIfNotCreator() public {
        launchCampaign();
        vm.prank(alice);
        vm.expectRevert("not creator");
        crowdFund.cancelCampaign(1);
    }

    function test_RevertIfAlreadyStarted() public {
        launchCampaign();
        skip(2 days);
        vm.expectRevert("started");
        crowdFund.cancelCampaign(1);
    }
}

contract Pledge is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;
    address alice = vm.addr(1);

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));

        vm.label(alice, "Alice");
        deal(address(token), alice, 1000);
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) + 1 days, // start in 1 day from now
            uint32(block.timestamp) + 7 days // end in 7 days from now
        );
    }

    function testFuzz_Pledge(uint256 amount) public {
        launchCampaign();
        skip(1 days);

        vm.assume(amount <= 1000);
        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        crowdFund.pledge(1, amount);
        vm.stopPrank();
        assertEq(crowdFund.pledgedAmount(1, address(alice)), amount);
    }

    function test_RevertIfCampaignNotStarted() public {
        launchCampaign();

        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        vm.expectRevert("not started");
        crowdFund.pledge(1, 100);
        assertEq(crowdFund.pledgedAmount(1, address(alice)), 0);
    }

    function test_RevertIfCampaignEnded() public {
        launchCampaign();
        skip(8 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        vm.expectRevert("ended");
        crowdFund.pledge(1, 100);
        assertEq(crowdFund.pledgedAmount(1, address(alice)), 0);
    }
}

contract Unpledge is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;
    address alice = vm.addr(1);

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));

        vm.label(alice, "Alice");
        deal(address(token), alice, 1000);
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) + 1 days, // start in 1 day from now
            uint32(block.timestamp) + 7 days // end in 7 days from now
        );
    }

    function testFuzz_Unpledge(uint256 amount) public {
        launchCampaign();
        skip(1 days);

        vm.assume(amount <= 1000);
        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        crowdFund.pledge(1, amount);
        crowdFund.unpledge(1, amount);
        vm.stopPrank();
        assertEq(crowdFund.pledgedAmount(1, address(alice)), 0);
    }

    function test_RevertIfCampaignEnded() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        crowdFund.pledge(1, 100);
        skip(7 days);
        vm.expectRevert("ended");
        crowdFund.unpledge(1, 100);
        vm.stopPrank();
    }
}

contract Claim is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;
    address alice = vm.addr(1);

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));

        vm.label(alice, "Alice");
        deal(address(token), alice, 10000);
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) + 1 days, // start in 1 day from now
            uint32(block.timestamp) + 7 days // end in 7 days from now
        );
    }

    function testFuzz_Claim(uint256 amount) public {
        launchCampaign();
        skip(1 days);

        amount = bound(amount, 1000, 10000);
        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, amount);
        vm.stopPrank();
        skip(7 days);
        crowdFund.claim(1);
        assertEq(token.balanceOf(address(this)), amount);
    }

    function test_RevertIfClaimerNotCreator() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, 1000);
        vm.stopPrank();
        skip(7 days);
        vm.prank(alice);
        vm.expectRevert("not creator");
        crowdFund.claim(1);
    }

    function test_RevertIfCampaignNotEnded() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, 1000);
        vm.stopPrank();
        vm.expectRevert("not ended");
        crowdFund.claim(1);
    }

    function test_RevertIfNotEnoughPledged() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, 100);
        vm.stopPrank();
        skip(7 days);
        vm.expectRevert("pledged < goal");
        crowdFund.claim(1);
    }

    function test_RevertIfAlreadyClaimed() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, 1000);
        vm.stopPrank();
        skip(7 days);
        crowdFund.claim(1);
        assertEq(token.balanceOf(address(this)), 1000);
        vm.expectRevert("claimed");
        crowdFund.claim(1);
    }
}

contract Refund is Test {
    MyERC20 public token;
    CrowdFund public crowdFund;
    address alice = vm.addr(1);

    function setUp() public {
        token = new MyERC20();
        crowdFund = new CrowdFund(address(token));

        vm.label(alice, "Alice");
        deal(address(token), alice, 10000);
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp) + 1 days, // start in 1 day from now
            uint32(block.timestamp) + 7 days // end in 7 days from now
        );
    }

    function testFuzz_Refund(uint256 amount) public {
        launchCampaign();
        skip(1 days);

        vm.assume(amount < 1000);
        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        crowdFund.pledge(1, amount);
        skip(7 days);
        crowdFund.refund(1);
        assertEq(token.balanceOf(address(alice)), 10000);
    }

    function test_RevertIfCampaignNotEnded() public {
        launchCampaign();
        skip(1 days);

        vm.startPrank(alice);
        token.approve(address(crowdFund), 1000);
        crowdFund.pledge(1, 100);
        vm.expectRevert("not ended");
        crowdFund.refund(1);
    }

    function test_RevertIfPledgedGoalMet(uint256 amount) public {
        launchCampaign();
        skip(1 days);

        amount = bound(amount, 1000, 10000);
        vm.startPrank(alice);
        token.approve(address(crowdFund), 10000);
        crowdFund.pledge(1, amount);
        skip(7 days);
        vm.expectRevert("pledged >= goal");
        crowdFund.refund(1);
    }
}
