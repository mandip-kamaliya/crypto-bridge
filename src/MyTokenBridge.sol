// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OApp} from "@layerzerolabs/lz-oapp/contracts/OApp.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MyTokenBridge is OApp{
    IERC20 public immutable originalToken;
    uint32 public destinationEid;
}
