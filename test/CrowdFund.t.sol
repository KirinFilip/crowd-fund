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
            uint32(block.timestamp) + 7 days // end in 8 days from now
        );
    }

    function test_CancelCampaign() public {
        launchCampaign();
        crowdFund.cancelCampaign(1);
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
    }

    function launchCampaign() public {
        crowdFund.launchCampaign(
            1000,
            uint32(block.timestamp),
            uint32(block.timestamp) + 7 days
        );
    }
}
