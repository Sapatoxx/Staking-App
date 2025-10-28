// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    StakingApp stakingApp;
    StakingToken stakingToken;
    //Staking token parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    //Staking app parameters
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 1000000; //60 seconds
    uint256 fixedStakingAmount_ = 10; //10 tokens
    uint256 rewardPerPeriod_ = 1 ether; //1 token

    address randomUser = vm.addr(2);

    function setUp() external {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(
            address(stakingToken),
            owner_,
            stakingPeriod_,
            fixedStakingAmount_,
            rewardPerPeriod_
        );
    }

    function testStakingTokenCorrectlyDeployed() external view {
        assert(address(stakingToken) != address(0));
    }

    function testStakingAppCorrectlyDeployed() external view {
        assert(address(stakingApp) != address(0));
    }

    function testShouldRevertIfNotOwner() external {
        uint256 newStakingPeriod_ = 1;

        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
    }

    function testShouldChangePeriod() external {
        vm.startPrank(owner_);
        uint256 newStakingPeriod_ = 1; //200 seconds

        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();

        assert(stakingPeriodBefore != stakingPeriodAfter);
        assert(stakingPeriodAfter == newStakingPeriod_);

        vm.stopPrank();
    }

    function testContractRecievesEtherCorrectly() external {
        vm.startPrank(owner_);

        uint256 etherValue = 1 ether;
        vm.deal(owner_, 1 ether); //El primer parámetro nos indica la persona que va a recibir el dinero y el segundo nos indica la cantidad de ether que le queremos mandar (estamos "imprimiendo un ether" para mandárselo al owner). Aseguramos que el contrato empieza con algo de ether con la funcion vm.deal()

        uint256 balanceBefore = address(stakingApp).balance;  //address(stakingApp).balance nos da el balance de ether del contrato que coloquemos dentro del parentesis
        (bool success, ) = address(stakingApp).call{value: etherValue}(""); //para un bool que se llama success, el cual tiene que dar "true", la direccion de llamada de stakingApp, la llamamos y le transferimos la cantidad de etherValue;
        uint256 balanceAfter = address(stakingApp).balance;
        require(success, "Ether transfer failed");

        assert(balanceAfter - balanceBefore == etherValue);

        vm.stopPrank();
    }

    //Deposit function testing
    function testIncorrectAmountShouldRevert() external {
        vm.startPrank(randomUser);

        uint256 depositAmount = 1; //Incorrect amount
        vm.expectRevert("Incorrect Amount");
        stakingApp.depositTokens(depositAmount);

        vm.stopPrank();
    }

    function testDepositTokensCorrectly() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //Mint some tokens to the user

        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); //Tenemos que aprobar al contrato que gaste nuestros tokens antes de hacer el deposit, sino, la funcion transferFrom() dentro de depositTokens() va a fallar
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();
    }

    function testUserCanNotDepositMoreThanOnce() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); //Mint some tokens to the user

        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); //Tenemos que aprobar al contrato que gaste nuestros tokens antes de hacer el deposit, sino, la funcion transferFrom() dentro de depositTokens() va a fallar
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        vm.expectRevert("User already has staked tokens");
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }

    //Withdraw function testing
    function testCanOnlyWithdrawZeroTokensWithoutDeposit() external {
        vm.startPrank(randomUser);
        stakingApp.withdrawTokens(); //el usuario no ha hecho deposit, por tanto su balance es 0, y al hacer withdraw se intenta transferir 0 tokens, lo cual es correcto
        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        assert(userBalanceAfter == userBalanceBefore);
        vm.stopPrank();
    }

    function testWithdrawTokensCrectly() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); //Tenemos que aprobar al contrato que gaste nuestros tokens antes de hacer el deposit, sino, la funcion transferFrom() dentro de depositTokens() va a fallar
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        uint256 userBalanceInMapping = stakingApp.userStakedBalance(randomUser);
        uint256 userBalanceBefore2 = IERC20(stakingToken).balanceOf(randomUser); //.balanceOf nos da el balance de tokens del usuario
        stakingApp.withdrawTokens(); //el usuario no ha hecho deposit, por tanto su balance es 0, y al hacer withdraw se intenta transferir 0 tokens, lo cual es correcto
        uint256 userBalanceAfter2 = IERC20(stakingToken).balanceOf(randomUser);

        assert(userBalanceAfter2 == userBalanceBefore2 + userBalanceInMapping);

        vm.stopPrank();
    }

    //Claim rewards function testing
    function testCanNotClaimIfNotStaking() external {
        vm.startPrank(randomUser);

        vm.expectRevert("Not staking the fixed amount");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testCanNotClaimIfStakingPeriodNotPassed() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); 
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.expectRevert("Staking period not yet passed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testShouldRevertIfNotEther() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); 
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.warp(block.timestamp + stakingPeriod_); //Avanzamos el tiempo del blockchain para simular el paso del tiempo
        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards(); //tiene que fallar porque el contrato no tiene ether para mandar la recompensa

        vm.stopPrank();
    }

    function testCanClaimRewardsCorrectly() external {

        vm.startPrank(randomUser);
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        uint256 userBalanceBefore = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount); 
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userStakedBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);
        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 rewardAmount = 100000 ether;
        vm.deal(owner_ , rewardAmount); //Aseguramos que el owner tiene ether para mandar al contrato
        (bool success, ) = address(stakingApp).call{value: rewardAmount}(""); //Mandamos ether al contrato para que pueda pagar las recompensas
        require(success, "Ether transfer to contract failed");
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_); //Avanzamos el tiempo del blockchain para simular el paso del tiempo
        uint256 etherAmountBefore = address(randomUser).balance; //Balance de ether del usuario antes de reclamar la recompensa
        stakingApp.claimRewards(); //tiene que fallar porque el contrato no tiene ether para mandar la recompensa
        uint256 etherAmountAfter = address(randomUser).balance; //Balance de ether del usuario antes de reclamar la recompensa
        uint256 elapsePeriod = stakingApp.elapsePeriod(randomUser);

        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsePeriod == block.timestamp);
        
        vm.stopPrank();
    }
}
