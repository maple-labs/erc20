// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { InvariantTest, TestUtils } from "../../modules/contract-test-utils/contracts/test.sol";

import { IERC20 } from "../interfaces/IERC20.sol";

import { ERC20 } from "../ERC20.sol";

import { ERC20User } from "./accounts/ERC20User.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract ERC20BaseTest is TestUtils {

    address internal immutable self = address(this);

    bytes internal constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    MockERC20 internal _token;

    function setUp() public virtual {
        _token = new MockERC20("Token", "TKN", 18);
    }

    function invariant_metadata() public {
        assertEq(_token.name(),     "Token");
        assertEq(_token.symbol(),   "TKN");
        assertEq(_token.decimals(), 18);
    }

    function testFuzz_metadata(string memory name_, string memory symbol_, uint8 decimals_) public {
        MockERC20 mockToken = new MockERC20(name_, symbol_, decimals_);

        assertEq(mockToken.name(),     name_);
        assertEq(mockToken.symbol(),   symbol_);
        assertEq(mockToken.decimals(), decimals_);
    }

    function testFuzz_mint(address account_, uint256 amount_) public {
        _token.mint(account_, amount_);

        assertEq(_token.totalSupply(),       amount_);
        assertEq(_token.balanceOf(account_), amount_);
    }

    function testFuzz_burn(address account_, uint256 amount0_, uint256 amount1_) public {
        if (amount1_ > amount0_) return;  // Mint amount must exceed burn amount.

        _token.mint(account_, amount0_);
        _token.burn(account_, amount1_);

        assertEq(_token.totalSupply(),       amount0_ - amount1_);
        assertEq(_token.balanceOf(account_), amount0_ - amount1_);
    }

    function testFuzz_approve(address account_, uint256 amount_) public {
        assertTrue(_token.approve(account_, amount_));

        assertEq(_token.allowance(self, account_), amount_);
    }

    function testFuzz_increaseAllowance(address account_, uint256 initialAmount_, uint256 addedAmount_) public {
        initialAmount_ = constrictToRange(initialAmount_, 0, type(uint256).max / 2);
        addedAmount_   = constrictToRange(addedAmount_,   0, type(uint256).max / 2);

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(self, account_), initialAmount_);

        assertTrue(_token.increaseAllowance(account_, addedAmount_));

        assertEq(_token.allowance(self, account_), initialAmount_ + addedAmount_);
    }

    function testFuzz_decreaseAllowance_infiniteApproval(address account_, uint256 subtractedAmount_) public {
        uint256 MAX_UINT256 = type(uint256).max;

        subtractedAmount_ = constrictToRange(subtractedAmount_, 0, MAX_UINT256);

        _token.approve(account_, MAX_UINT256);

        assertEq(_token.allowance(self, account_), MAX_UINT256);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(_token.allowance(self, account_), MAX_UINT256);
    }

    function testFuzz_decreaseAllowance_nonInfiniteApproval(address account_, uint256 initialAmount_, uint256 subtractedAmount_) public {
        initialAmount_    = constrictToRange(initialAmount_,    0, type(uint256).max - 1);
        subtractedAmount_ = constrictToRange(subtractedAmount_, 0, initialAmount_);

        _token.approve(account_, initialAmount_);

        assertEq(_token.allowance(self, account_), initialAmount_);

        assertTrue(_token.decreaseAllowance(account_, subtractedAmount_));

        assertEq(_token.allowance(self, account_), initialAmount_ - subtractedAmount_);
    }

    function testFuzz_transfer(address account_, uint256 amount_) public {
        _token.mint(self, amount_);

        assertTrue(_token.transfer(account_, amount_));

        assertEq(_token.totalSupply(), amount_);

        if (self == account_) {
            assertEq(_token.balanceOf(self), amount_);
        } else {
            assertEq(_token.balanceOf(self),     0);
            assertEq(_token.balanceOf(account_), amount_);
        }
    }

    function testFuzz_transferFrom(address recipient_, uint256 approval_, uint256 amount_) public {
        approval_ = constrictToRange(approval_, 0, type(uint256).max - 1);
        amount_   = constrictToRange(amount_,   0, approval_);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), self, approval_);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(), amount_);

        approval_ = address(owner) == self ? approval_ : approval_ - amount_;

        assertEq(_token.allowance(address(owner), self), approval_);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_), amount_);
        }
    }

    function testFuzz_transferFrom_infiniteApproval(address recipient_, uint256 amount_) public {
        uint256 MAX_UINT256 = type(uint256).max;

        amount_ = constrictToRange(amount_, 0, MAX_UINT256);

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);
        owner.erc20_approve(address(_token), self, MAX_UINT256);

        assertEq(_token.balanceOf(address(owner)),       amount_);
        assertEq(_token.totalSupply(),                   amount_);
        assertEq(_token.allowance(address(owner), self), MAX_UINT256);

        assertTrue(_token.transferFrom(address(owner), recipient_, amount_));

        assertEq(_token.totalSupply(),                   amount_);
        assertEq(_token.allowance(address(owner), self), MAX_UINT256);

        if (address(owner) == recipient_) {
            assertEq(_token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(_token.balanceOf(address(owner)), 0);
            assertEq(_token.balanceOf(recipient_),     amount_);
        }
    }

    function testFuzz_transfer_insufficientBalance(address recipient_, uint256 amount_) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User account = new ERC20User();

        _token.mint(address(account), amount_ - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        account.erc20_transfer(address(_token), recipient_, amount_);

        _token.mint(address(account), 1);
        account.erc20_transfer(address(_token), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientAllowance(address recipient_, uint256 amount_) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_);

        owner.erc20_approve(address(_token), self, amount_ - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        _token.transferFrom(address(owner), recipient_, amount_);

        owner.erc20_approve(address(_token), self, amount_);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

    function testFuzz_transferFrom_insufficientBalance(address recipient_, uint256 amount_) public {
        amount_ = amount_ == 0 ? 1 : amount_;

        ERC20User owner = new ERC20User();

        _token.mint(address(owner), amount_ - 1);
        owner.erc20_approve(address(_token), self, amount_);

        vm.expectRevert(ARITHMETIC_ERROR);
        _token.transferFrom(address(owner), recipient_, amount_);

        _token.mint(address(owner), 1);
        _token.transferFrom(address(owner), recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
    }

}

contract ERC20PermitTest is TestUtils {

    bytes internal constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    uint256 internal constant S_VALUE_INCLUSIVE_UPPER_BOUND = uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);
    uint256 internal constant WAD = 10 ** 18;

    address internal _owner;
    address internal _spender;

    uint256 internal _skOwner   = 1;
    uint256 internal _skSpender = 2;
    uint256 internal _nonce     = 0;
    uint256 internal _deadline  = 5_000_000_000;  // Timestamp far in the future

    ERC20     internal _token;
    ERC20User internal _user;

    function setUp() public virtual {
        _owner   = vm.addr(_skOwner);
        _spender = vm.addr(_skSpender);

        vm.warp(_deadline - 52 weeks);

        _token = new ERC20("Maple Token", "MPL", 18);
        _user  = new ERC20User();
    }

    function test_typehash() external {
        assertEq(_token.PERMIT_TYPEHASH(), keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"));
    }

    // NOTE: Virtual so inheriting tests can override with different DOMAIN_SEPARATORs because of different addresses
    function test_domainSeparator() public virtual {
        assertEq(_token.DOMAIN_SEPARATOR(), 0x4b8187b77163c02c27b65aa9de86b76c6e4e236f6432e5656ec164ea1e87ba87);
    }

    function test_initialState() public {
        assertEq(_token.nonces(_owner),              0);
        assertEq(_token.allowance(_owner, _spender), 0);
    }

    function testFuzz_permit(uint256 amount_) public {
        uint256 startingNonce = _token.nonces(_owner);
        uint256 expectedNonce = startingNonce + 1;

        (
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = _getValidPermitSignature(address(_token), _owner, _spender, amount_, startingNonce, _deadline, _skOwner);

        _user.erc20_permit(address(_token), _owner, _spender, amount_, _deadline, v, r, s);

        assertEq(_token.nonces(_owner),              expectedNonce);
        assertEq(_token.allowance(_owner, _spender), amount_);
    }

    function testFuzz_permit_multiple(bytes32 seed_) public {
        for (uint256 i; i < 10; ++i) {
            testFuzz_permit(uint256(keccak256(abi.encodePacked(seed_, i))));
        }
    }

    function test_permit_zeroAddress() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), address(0), _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_differentSpender() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, address(1111), 1000, 0, _deadline, _skOwner);

        // Using permit with unintended spender should fail.
        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_ownerSignerMismatch() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skSpender);

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_withExpiry() public {
        uint256 expiry = 482112000 + 1 hours;

        // Expired permit should fail
        vm.warp(482112000 + 1 hours + 1);

        assertEq(block.timestamp, 482112000 + 1 hours + 1);

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, expiry, _skOwner);

        vm.expectRevert("ERC20:P:EXPIRED");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, expiry, v, r, s);

        assertEq(_token.allowance(_owner, _spender), 0);
        assertEq(_token.nonces(_owner),              0);

        // Valid permit should succeed
        vm.warp(482112000 + 1 hours);

        assertEq(block.timestamp, 482112000 + 1 hours);

        ( v, r, s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, expiry, _skOwner);

        _user.erc20_permit(address(_token), _owner, _spender, 1000, expiry, v, r, s);

        assertEq(_token.allowance(_owner, _spender), 1000);
        assertEq(_token.nonces(_owner),              1);
    }

    function test_permit_replay() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        // First time should succeed
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);

        // Second time nonce has been consumed and should fail
        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_earlyNonce() public {
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 1, _deadline, _skOwner);

        // Previous nonce of 0 has not been consumed yet, so nonce of 1 should fail.
        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_differentVerifier() public {
        address someToken = address(new ERC20("Some Token", "ST", 18));

        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(someToken, _owner, _spender, 1000, 0, _deadline, _skOwner);

        // Using permit with unintended verifier should fail.
        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, s);
    }

    function test_permit_badS() public {
        ( uint8 v, bytes32 r, ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        // Send in an s that is above the upper bound.
        bytes32 badS = bytes32(S_VALUE_INCLUSIVE_UPPER_BOUND + 1);
        vm.expectRevert("ERC20:P:MALLEABLE");
        _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, v, r, badS);
    }

    function test_permit_badV() public {
        // Get valid signature. The `v` value is the expected v value that will cause `permit` to succeed, and must be 27 or 28.
        // Any other value should fail.
        // If v is 27, then 28 should make it past the MALLEABLE require, but should result in an invalid signature,
        // and vice versa when v is 28.
        ( uint8 v, bytes32 r, bytes32 s ) = _getValidPermitSignature(address(_token), _owner, _spender, 1000, 0, _deadline, _skOwner);

        for (uint8 i; i <= type(uint8).max; i++) {
            if (i == type(uint8).max) {
                break;
            } else if (i != 27 && i != 28) {
                vm.expectRevert("ERC20:P:MALLEABLE");
            } else {
                if (i == v) continue;

                // Should get past the Malleable require check as 27 or 28 are valid values for s.
                vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
            }

            _user.erc20_permit(address(_token), _owner, _spender, 1000, _deadline, i, r, s);
        }
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(address token_, address owner_, address spender_, uint256 amount_, uint256 nonce_, uint256 deadline_)
        internal view returns (bytes32 digest_)
    {
        return keccak256(
            abi.encodePacked(
                '\x19\x01',
                IERC20(token_).DOMAIN_SEPARATOR(),
                keccak256(abi.encode(IERC20(token_).PERMIT_TYPEHASH(), owner_, spender_, amount_, nonce_, deadline_))
            )
        );
    }

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ownerSk_
    )
        internal returns (uint8 v_, bytes32 r_, bytes32 s_)
    {
        return vm.sign(ownerSk_, _getDigest(token_, owner_, spender_, amount_, nonce_, deadline_));
    }

}

contract ERC20Invariants is TestUtils, InvariantTest {

    BalanceSum internal _balanceSum;

    function setUp() public {
        _balanceSum = new BalanceSum();

        addTargetContract(address(_balanceSum));
    }

    function invariant_balanceSum() public {
        assertEq(_balanceSum.token().totalSupply(), _balanceSum.sum());
    }

}

contract BalanceSum {

    MockERC20 public token = new MockERC20("Token", "TKN", 18);

    uint256 public sum;

    function mint(address recipient_, uint256 amount_) public {
        token.mint(recipient_, amount_);
        sum += amount_;
    }

    function burn(address owner_, uint256 amount_) public {
        token.burn(owner_, amount_);
        sum -= amount_;
    }

    function approve(address spender_, uint256 amount_) public {
        token.approve(spender_, amount_);
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) public {
        token.transferFrom(owner_, recipient_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) public {
        token.transfer(recipient_, amount_);
    }

}
