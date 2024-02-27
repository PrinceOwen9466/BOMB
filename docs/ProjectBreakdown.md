Project name is $BOMB

the idea is that its the first truly decentralized double rewards rebase token

no presale, no team allocation, and the tax is 10/10 all of which is eth reflections. So no treasury, no buyback, no tax going to liq etc. Just pure eth reflections.  Tokens are collected by tax, sold periodically by contract (as often as possible to avoid big sells) and rewarded as eth to everyone (except to lp or burn wallet obviously). 
The rebase needs to be fully automated, so its probably best to fork safuu instead of titano (which had a scuffed ca that required python script to trigger rebase). 
IT should also have some anti snipe features i guess, blacklist function, high tax and clog. 

safuu ca: (they turned off rebase) 0xE5bA47fD94CB645ba4119222e34fB33F59C7CD90

baked beans: ca https://bscscan.com/address/0xE2D26507981A4dAaaA8040bae1846C14E0Fb56bF
for bakes beans a 1:1 fork will do, except that it will work with eth instead of bnb obviously

Reflections are similar to dividends but they take a fee from each transaction and either periodically or immediately disperse it to all addresses except the burn address and LP address (these would have to be set post deployment but some contracts do it deterministically at construction, that is the deployment triggers LP creation then gets the LP address).