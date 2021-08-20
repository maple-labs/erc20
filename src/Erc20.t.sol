pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Erc20.sol";

contract Erc20Test is DSTest {
    Erc20 erc;

    function setUp() public {
        erc = new Erc20();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
