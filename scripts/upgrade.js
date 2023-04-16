// scripts/upgrade.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const CrowdFundingV2 = await ethers.getContractFactory('CrowdFundingV2');
  console.log('Upgrading CrowdFundingV2...');

  // DeployCrowdFundingV2 as an upgrade with proxy contract address provided
  await upgrades.upgradeProxy('0x53F0253603289700B091F96d1f9aBDbDFCd0ec3d', CrowdFundingV2);
  console.log('CrowdFunding contract Upgraded!');
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  