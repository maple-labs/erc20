// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20StorageLayout } from "./interfaces/IERC20StorageLayout.sol";

contract ERC20StorageLayout is IERC20StorageLayout {

    string public override name;
    string public override symbol;

    uint8 public override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

}
