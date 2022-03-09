// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./IERC20.sol";

/// @title Interface of the ERC20 standard with the addition of permit functionality outlined in EIP 2612
interface IERC20Permit is IERC20 {

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Returns the permit type hash.
     *  @return hash_ The typehash for the commit.
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 hash_);

    /**
     *  @dev    Returns the nonce for the given owner.
     *  @param  owner The addreses of the owner account.
     *  @return nonce_ The current nonce.
     */
    function nonces(address owner) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domain_ The domain for the contract.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domain_);

}
