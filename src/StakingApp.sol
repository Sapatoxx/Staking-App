// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract stakingApp is Ownable {

  //variables
  address public stakingToken;
  constructor(address _stakingToken, address owner_) Ownable(owner_) {
    stakingToken = _stakingToken;
  }
}
