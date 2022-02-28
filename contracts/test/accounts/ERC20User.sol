// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 }       from "../../interfaces/IERC20.sol";
import { IERC20Permit } from "../../interfaces/IERC20Permit.sol";

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

    function try_erc20_approve(address token_, address spender, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount_));
    }

    function try_erc20_transfer(address token_, address recipient_, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.transfer.selector, recipient_, amount_));
    }

    function try_erc20_transferFrom(address token_, address owner_, address recipient_, uint256 amount_) external returns (bool ok_) {
        ( ok_, ) = token_.call(abi.encodeWithSelector(IERC20.transferFrom.selector, owner_, recipient_, amount_));
    }

}

contract ERC20PermitUser is ERC20User {

    /************************/
    /*** Direct Functions ***/
    /************************/

    function erc20_permit(
        address mplToken,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        IERC20Permit(mplToken).permit(owner, spender, amount, deadline, v, r, s);
    }


    /*********************/
    /*** Try Functions ***/
    /*********************/    

    function try_erc20_permit(
        address mplToken,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external returns (bool ok)
    {
        (ok,) = mplToken.call(abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s));
    }

}