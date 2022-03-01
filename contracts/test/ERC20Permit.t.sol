// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { ERC20PermitUser } from "./accounts/ERC20User.sol";

import { MockERC20Permit } from "./mocks/MockERC20.sol";

import { Hevm }          from "./utils/Hevm.sol";
import { InvariantTest } from "./utils/InvariantTest.sol";

import { ERC20Test, MockERC20 } from "./ERC20.t.sol";

contract ERC20BaseTest is ERC20Test {

    function setUp() override public {
        token = MockERC20(address(new MockERC20Permit("Token", "TKN", 18)));
    }

}

contract ERC20PermitTest is DSTest {

    Hevm hevm;

    MockERC20Permit token;
    ERC20PermitUser user;

    uint256 skOwner   = 1;
    uint256 skSpender = 2;
    uint256 nonce     = 0;
    uint256 deadline  = 5000000000; // Timestamp far in the future

    address owner;
    address spender;

    uint256 constant WAD = 10 ** 18;

    function setUp() external {
        hevm = Hevm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

        owner   = hevm.addr(skOwner);
        spender = hevm.addr(skSpender);

        hevm.warp(deadline - 52 weeks);
        token = new MockERC20Permit("Maple Token", "MPL", 18);
        user  = new ERC20PermitUser();
    }

    function test_typehash() external {
        assertEq(token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"));
    }

    function test_domainSeparator() external {
        assertEq(token.DOMAIN_SEPARATOR(), 0x06c0ee43424d25534e5af6b6af862333b542f6583ff9948b8299442926099eec);
    }

    function test_permit() external {
        uint256 amount = 10 * WAD;
        assertEq(token.nonces(owner),             0);
        assertEq(token.allowance(owner, spender), 0);

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(user.try_erc20_permit(address(token), owner, spender, amount, deadline, v, r, s));

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitZeroAddress() external {
        uint256 amount = 10 * WAD;
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(!user.try_erc20_permit(address(token), address(0), spender, amount, deadline, v, r, s));
    }

    function test_permitNonOwnerAddress() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);
        assertTrue(!user.try_erc20_permit(address(token), spender, owner, amount, deadline, v,  r,  s));

        ( v, r, s ) = _getValidPermitSignature(amount, spender, skSpender, deadline);
        assertTrue(!user.try_erc20_permit(address(token), owner, spender, amount, deadline, v, r, s));
    }

    function test_permitWithExpiry() external {
        uint256 amount = 10 * WAD;
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        hevm.warp(482112000 + 1 hours + 1);
        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);
        assertTrue(!user.try_erc20_permit(address(token), owner, spender, amount, expiry, v, r, s));

        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner),             0);

        // Valid permit should succeed
        hevm.warp(482112000 + 1 hours);
        assertEq(block.timestamp, 482112000 + 1 hours);

        ( v, r, s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);
        assertTrue(user.try_erc20_permit(address(token), owner, spender, amount, expiry, v, r, s));

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitReplay() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        // First time should succeed
        assertTrue(user.try_erc20_permit(address(token), owner, spender, amount, deadline, v, r, s));

        // Second time nonce has been consumed and should fail
        assertTrue(!user.try_erc20_permit(address(token), owner, spender, amount, deadline, v, r, s));
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(address owner_, address spender_, uint256 value_, uint256 nonce_, uint256 deadline_) internal view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(token.PERMIT_TYPEHASH(), owner_, spender_, value_, nonce_, deadline_))
            )
        );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(uint256 value, address owner_, uint256 ownersk, uint256 deadline_) internal view returns (uint8, bytes32, bytes32) {
        bytes32 digest = getDigest(owner_, spender, value, nonce, deadline_);
        ( uint8 v, bytes32 r, bytes32 s ) = hevm.sign(ownersk, digest);
        return (v, r, s);
    }

}

contract ERC20Invariants is DSTest, InvariantTest {

    BalanceSum balanceSum;

    function setUp() public {
        balanceSum = new BalanceSum();
        addTargetContract(address(balanceSum));
    }

    function invariant_balanceSum() public {
        assertEq(balanceSum.token().totalSupply(), balanceSum.sum());
    }

}

contract BalanceSum {

    MockERC20Permit public token = new MockERC20Permit("Token", "TKN", 18);

    uint256 public sum;

    function mint(address account, uint256 amount) external {
        token.mint(account, amount);
        sum += amount;
    }

    function burn(address account, uint256 amount) external {
        token.burn(account, amount);
        sum -= amount;
    }

    function approve(address dst, uint256 amount) external {
        token.approve(dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        token.transferFrom(src, dst, amount);
    }

    function transfer(address dst, uint256 amount) external {
        token.transfer(dst, amount);
    }

}
