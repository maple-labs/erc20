// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { ERC20Permit } from "../ERC20Permit.sol";

import { ERC20PermitUser } from "./accounts/ERC20User.sol";

import { MockERC20Permit } from "./mocks/MockERC20.sol";

import { Vm }            from "./utils/Vm.sol";
import { InvariantTest } from "./utils/InvariantTest.sol";

import { ERC20Test, MockERC20 } from "./ERC20.t.sol";

contract ERC20PermitBaseTest is ERC20Test {

    function setUp() override public {
        token = MockERC20(address(new MockERC20Permit("Token", "TKN", 18)));
    }

}

contract ERC20PermitTest is DSTest {

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    bytes constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    ERC20Permit     token;
    ERC20PermitUser user;

    uint256 skOwner   = 1;
    uint256 skSpender = 2;
    uint256 nonce     = 0;
    uint256 deadline  = 5_000_000_000;  // Timestamp far in the future

    address owner;
    address spender;

    uint256 constant WAD = 10 ** 18;

    function setUp() public virtual {
        owner   = vm.addr(skOwner);
        spender = vm.addr(skSpender);

        vm.warp(deadline - 52 weeks);
        token = new ERC20Permit("Maple Token", "MPL", 18);
        user  = new ERC20PermitUser();
    }

    function test_typehash() external {
        assertEq(token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"));
    }

    // NOTE: Virtual so inheriting tests can override with different DOMAIN_SEPARATORs because of different addresses
    function test_domainSeparator() external virtual {
        assertEq(token.DOMAIN_SEPARATOR(), 0x06c0ee43424d25534e5af6b6af862333b542f6583ff9948b8299442926099eec);
    }

    function test_permit() external {
        uint256 amount = 10 * WAD;
        assertEq(token.nonces(owner),             0);
        assertEq(token.allowance(owner, spender), 0);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitZeroAddress() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        vm.expectRevert(bytes("ERC20Permit:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), address(0), spender, amount, deadline, 17, r, s);  // https://ethereum.stackexchange.com/questions/69328/how-to-get-the-zero-address-from-ecrecover

        vm.expectRevert(bytes("ERC20Permit:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), address(0), spender, amount, deadline, v, r, s);
    }

    function test_permitNonOwnerAddress() external {
        uint256 amount = 10 * WAD;

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        vm.expectRevert(bytes("ERC20Permit:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), spender, owner, amount, deadline, v,  r,  s);

        ( v, r, s ) = _getValidPermitSignature(amount, spender, skSpender, deadline);

        vm.expectRevert(bytes("ERC20Permit:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
    }

    function test_permitWithExpiry() external {
        uint256 amount = 10 * WAD;
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        vm.warp(482112000 + 1 hours + 1);
        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);

        vm.expectRevert(bytes("ERC20Permit:EXPIRED"));
        user.erc20_permit(address(token), owner, spender, amount, expiry, v, r, s);

        assertEq(token.allowance(owner, spender), 0);
        assertEq(token.nonces(owner),             0);

        // Valid permit should succeed
        vm.warp(482112000 + 1 hours);
        assertEq(block.timestamp, 482112000 + 1 hours);

        ( v, r, s ) = _getValidPermitSignature(amount, owner, skOwner, expiry);
        user.erc20_permit(address(token), owner, spender, amount, expiry, v, r, s);

        assertEq(token.allowance(owner, spender), amount);
        assertEq(token.nonces(owner),             1);
    }

    function test_permitReplay() external {
        uint256 amount = 10 * WAD;
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(amount, owner, skOwner, deadline);

        // First time should succeed
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);

        // Second time nonce has been consumed and should fail
        vm.expectRevert(bytes("ERC20Permit:INVALID_SIGNATURE"));
        user.erc20_permit(address(token), owner, spender, amount, deadline, v, r, s);
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
    function _getValidPermitSignature(uint256 value_, address owner_, uint256 ownerSk_, uint256 deadline_) internal returns (uint8 v_, bytes32 r_, bytes32 s_) {
        bytes32 digest = _getDigest(owner_, spender, value_, nonce, deadline_);
        ( uint8 v, bytes32 r, bytes32 s ) = vm.sign(ownerSk_, digest);
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
