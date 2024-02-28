import { ethers } from "hardhat";

import IUniswapV2Router from '@uniswap/v2-core/build/IUniswapV2Callee.json'
import IUniswapV2Factory from '@uniswap/v2-core/build/IUniswapV2Factory.json'
import { IPancakeSwapFactory } from "../typechain-types";


async function main() {
  IUniswapV2Router
  const unir =new ethers.ContractFactory(IUniswapV2Factory.abi, IUniswapV2Factory.bytecode) 
  
  const uni = new ethers.ContractFactory(IUniswapV2Factory.abi, IUniswapV2Factory.bytecode);
  const factory = await uni.deploy() as IPancakeSwapFactory;
  
  factory.createPair()
  


  const bomb = await ethers.deployContract("BOMB_flattened");
  await bomb.waitForDeployment();

  console.log(
    `Deployed $BOMB to ${bomb.target}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
