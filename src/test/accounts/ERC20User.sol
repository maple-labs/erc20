// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "../../interfaces/IERC20.sol";

contract ERC20User {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function erc20_approve(address token_, address spender_, uint256 amount_) external {
        IERC20(token_).approve(spender_, amount_);
    }

    function erc20_transfer(address token_, address recipient_, uint256 amount_) external {
        IERC20(token_).transfer(recipient_, amount_);
    }

    function erc20_transferFrom(address token_, address owner_, address recipient_, uint256 amount_) external {
        IERC20(token_).transferFrom(owner_, recipient_, amount_);
    }

    /*********************/
    /*** Try Functions ***/
    /*********************/

    function try_erc20_approve(address token_, address spender_, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.approve.selector, spender_, amount_));
    }

    function try_erc20_transfer(address token_, address recipient_, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.transfer.selector, recipient_, amount_));
    }

    function try_erc20_transferFrom(address token_, address owner_, address recipient_, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.transferFrom.selector, owner_, recipient_, amount_));
    }

}
