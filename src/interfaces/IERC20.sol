// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20StorageLayout } from "./IERC20StorageLayout.sol";

/// @title Interface of the ERC20 standard as defined in the EIP.
interface IERC20 is IERC20StorageLayout {

    /**************/
    /*** Events ***/
    /**************/

    /**
     * @dev   Emits an event indicating that one account has set the allowance of another account over their tokens.
     * @param owner   Account that tokens are approved from.
     * @param spender Account that tokens are approved for.
     * @param amount  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev   Emits an event indicating that tokens have moved from one account to another.
     * @param from  Account that tokens have moved from.
     * @param to    Account that tokens have moved to.
     * @param amount Amount of tokens that have been transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /*****************************************/
    /*** External State-Changing Functions ***/
    /*****************************************/

    /**
     * @dev   Function that allows one account to set the allowance of another account over their tokens.
     * @dev   Emits an {Approval} event.
     * @param spender Account that tokens are approved for.
     * @param amount  Amount of tokens that have been approved.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev   Moves an amount of tokens from `msg.sender` to a specified account.
     * @dev   Emits a {Transfer} event.
     * @param recipient Account that recieves tokens.
     * @param amount    Amount of tokens that are transferred.
     * @return          Boolean amount indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev   Moves a pre-approved amount of tokens from a sender to a specified account.
     * @dev   Emits a {Transfer} event.
     * @dev   Emits an {Approval} event.
     * @param owner     Account that tokens are moving from.
     * @param recipient Account that recieves tokens.
     * @param amount    Amount of tokens that are transferred.
     */
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool);

}
