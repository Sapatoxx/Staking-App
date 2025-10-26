// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract stakingApp is Ownable {
  //variables
  address public stakingToken;
  uint256 public stakingPeriod; //in seconds
  uint256 public fixedStakingAmount; //Fixed staking amount of 10 tokens
  uint256 public rewardPerPeriod;//1 token reward per period
  mapping (address => uint256 ) public userStakedBalance;
  mapping (address => uint256 ) public elapsePeriod;

  //Events
  event changePeriod(uint256 newStakingPeriod_);
  event DepositTokens(address userAddress_, uint256 depositAmount_);
  event WithdrawTokens(address userAddress_, uint256 withdrawAmount_);
  event EtherSent (uint256 amount_);

  //Constructor
  constructor(address _stakingToken, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_) Ownable(owner_) {
    stakingToken = _stakingToken;
    stakingPeriod = stakingPeriod_;
    fixedStakingAmount = fixedStakingAmount_;
    rewardPerPeriod = rewardPerPeriod_;
  }

  ///////FUNCTIONS
  ////External functions
  //Deposit
  function depositTokens(uint256 tokenAmountToDeposit_) external {
    require(tokenAmountToDeposit_ == fixedStakingAmount, "Incorrect deposit amount, must be 10 tokens");
    require(userStakedBalance[msg.sender] == 0, "User already has staked tokens");
    IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountToDeposit_);
    userStakedBalance[msg.sender] += tokenAmountToDeposit_;
    elapsePeriod[msg.sender] = block.timestamp;
    emit DepositTokens(msg.sender, tokenAmountToDeposit_);
  }

  //Withdraw
  function withdrawTokens() external {
    uint256 userStakedBalance_ = userStakedBalance[msg.sender];   //Al transferir ether se "triggea" una funcion del smart contract que recibe el ether, en este caso la funcion receive() o fallback(), y esta función puede hacer que se llame a la función withdrawTokens(), y robar los fondos del contrato
    userStakedBalance[msg.sender] = 0; //Primero actualizar el estado antes de usar los tokens
    IERC20(stakingToken).transfer(msg.sender, userStakedBalance_); //En este caso lo podemos  usar el CEI pattern porque la funcion transfer() de IERC20 de OPENZEPPELIN no llama a ningún contrato externo, por tanto no hay riesgo de reentrancy attack. Si es otro transfer hay riesgo de reentrancy attack

    emit WithdrawTokens(msg.sender, userStakedBalance_);
  }

  //Claim rewards
  function claimRewards() external {
    //1. Check balance (queremos que el usuario tenga tokens staked)
    require(userStakedBalance[msg.sender] == fixedStakingAmount, "Not staking the fixed amount");

    //2. Calculate rewards amount -> calculamos el tiempo que ha pasado desde que el usuario hizo el stake menos el periodo de staking
    uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];  //block.stamp es el timestamp del bloque actual, al cual se le resta el timestamp de cuando el usuario hizo el stake
    require(elapsePeriod_ >= stakingPeriod, "Staking period not yet passed");

    //3. Update state
    elapsePeriod[msg.sender] = block.timestamp; //Reseteamos el tiempo de deposito para que el usuario pueda volver a reclamar recompensas despues de otro periodo de staking

    //4. Transfer rewards
    (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
    require(success, "Transfer failed");
  }

  ////Internal functions
  receive() external payable onlyOwner {  //Funcion para recibir ether en el contrato //El receive puede tener lógica
    emit EtherSent(msg.value);
  } 
  function changeStakingPeriod(uint256 newStakingPeriod_)  external onlyOwner {  //Colocamos el modificador onlyOwner para que solo el dueño del contrato pueda cambiar el periodo de staking, este modificador viene de la libreria OpenZeppelin
    stakingPeriod = newStakingPeriod_; 
    emit changePeriod(newStakingPeriod_);
  }
}
