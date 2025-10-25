// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract stakingApp is Ownable {

  //variables
  address public stakingToken;

  //Events
  event changePeriod(uint256 newStakingPeriod_);
  constructor(address _stakingToken, address owner_, uint256 stakingPeriod_) Ownable(owner_) {
    stakingToken = _stakingToken;
    stakingPeriod = stakingPeriod_;
  }

  ///////FUNCTIONS

  ////External functions
  //Deposit

  //Withdraw

  //Claim rewards

  ////Internal functions













  function changeStakingPeriod(uint256 newStakingPeriod_)  external onlyOwner {  //Colocamos el modificador onlyOwner para que solo el dueño del contrato pueda cambiar el periodo de staking, este modificador viene de la libreria OpenZeppelin
    stakingPeriod = newStakingPeriod_; 
    emit changePeriod(newStakingPeriod_);
  }




}
