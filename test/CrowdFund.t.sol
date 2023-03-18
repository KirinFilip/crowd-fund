// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {CrowdFund} from "../src/CrowdFund.sol";
import "../src/IERC20.sol";

contract Constructor is Test {
    IERC20 public token;
}
