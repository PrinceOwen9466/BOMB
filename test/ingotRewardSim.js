const { seconds } = require("@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time/duration");

const INGOT_REWARD_MULTIPLIER = 16;
const REFERRAL_REWARD_PER_THOUSAND = 12500;
const INGOT_FRAGMENT = 200;

function testIngotReferralReward() {
  const ores = 5000;
  const ingots = 6800;
  const ingotPM = Math.floor((ingots * INGOT_REWARD_MULTIPLIER) / INGOT_FRAGMENT);
  const rewardIncPercent = REFERRAL_REWARD_PER_THOUSAND + ingotPM;

  const referralOres = Math.floor((rewardIncPercent * ores) / (1000 * 100));


  console.log("Initial ores", ores)
  console.log("Initial ingots", ingots);

  console.log(`Ingot Multiplier ${ingotPM} => ${ingotPM / 1000}%`);
  console.log(`Reward Increase ${rewardIncPercent} => ${rewardIncPercent / 1000}%`);

  console.log(`Referral gets ${referralOres} ores`);
}

function testIngotTimeIncrease() {
  const secondsPassed = 5000;

  const ingots = 6800;
  const ingotPM = ingots / INGOT_FRAGMENT;
  const timeIncrease = (secondsPassed * ingots) / (INGOT_FRAGMENT * 100)

  console.log("\n\nIngot ratio: ", ingotPM);
  console.log("Time increase: ", timeIncrease);
  console.log("New time: ", secondsPassed + timeIncrease);
}

testIngotReferralReward();

console.log();console.log();console.log();
testIngotTimeIncrease();