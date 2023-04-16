// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const {ethers,upgrades} = require("hardhat");
async function main() {
  // Deploy the Gcoin contract first so its address will be available later
  const Gcoin = await ethers.getContractFactory(
    "Gcoin"
  );
  const gcoin = await Gcoin.deploy();
  await gcoin.deployed();

  console.log("Gcoin token contract deployed to: ", gcoin.address);

  // Now deploy the CrowdFunding contract
  //1296000 equals 15 day duration
  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  console.log('Deploying CrowdFunding...');
  const crowdFunding = await upgrades.deployProxy(CrowdFunding,
    [gcoin.address,1296000 ],
    {initializer:'initialize',
     kind:"uups"});
  
  await crowdFunding.deployed();

  console.log("CrowdFunding contract deployed to: ", crowdFunding.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
