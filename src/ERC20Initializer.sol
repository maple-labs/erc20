// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { ERC20StorageLayout } from "./ERC20StorageLayout.sol";

contract ERC20Initializer is ERC20StorageLayout {

    function _initialize(string memory _name, string memory _symbol, uint8 _decimals) internal {
        decimals = _decimals;
        name     = _name;
        symbol   = _symbol;
    }

}
