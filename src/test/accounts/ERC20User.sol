// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "../../interfaces/IERC20.sol";

contract ERC20User {

    /************************/
    /*** Direct Functions ***/
    /************************/
    function erc20_approve(address token, address recipient, uint256 amount) external {
        IERC20(token).approve(recipient, amount);
    }

    function erc20_transfer(address token, address recipient, uint256 amount) external {
        IERC20(token).transfer(recipient, amount);
    }

    function erc20_transferFrom(address token, address owner, address recipient, uint256 amount) external {
        IERC20(token).transferFrom(owner, recipient, amount);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/
    function try_erc20_approve(address token, address recipient, uint256 amount) external returns (bool ok) {
        (ok,) = token.call(abi.encodeWithSelector(IERC20.approve.selector, recipient, amount));
    }

    function try_erc20_transfer(address token, address recipient, uint256 amount) external returns (bool ok) {
        (ok,) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount));
    }

    function try_erc20_transferFrom(address token, address owner, address recipient, uint256 amount) external returns (bool ok) {
        (ok,) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, recipient, amount));
    }

}
