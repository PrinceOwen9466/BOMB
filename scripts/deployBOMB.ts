import { ethers } from "hardhat";

async function main() {
  const bomb = await ethers.deployContract("BOMB_flattened");
  await bomb.waitForDeployment();

  console.log(
    `Deployed $BOMB to ${bomb.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
