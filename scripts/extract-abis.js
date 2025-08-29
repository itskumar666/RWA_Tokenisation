#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Define the contracts we want to extract ABIs for
const CONTRACTS = [
  'RWA_Manager',
  'RWA_Coins', 
  'RWA_NFT',
  'RWA_VerifiedAssets',
  'StakingCoin',
  'LendingManager',
  'LendingVault',
  'NFTVault',
  'AuctionHouse'
];

// Output directory for ABIs
const OUTPUT_DIR = './Frontend/src/contracts/abis';
const ADDRESSES_FILE = './Frontend/src/contracts/addresses.js';

function extractABIs() {
  console.log('🔍 Extracting ABIs from compiled contracts...\n');

  // Create output directory if it doesn't exist
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const extractedABIs = {};
  const contractAddresses = {};

  CONTRACTS.forEach(contractName => {
    try {
      const contractDir = `./out/${contractName}.sol`;
      const contractFile = `${contractDir}/${contractName}.json`;
      
      if (fs.existsSync(contractFile)) {
        const contractData = JSON.parse(fs.readFileSync(contractFile, 'utf8'));
        
        if (contractData.abi) {
          // Save individual ABI file
          const abiOutputFile = path.join(OUTPUT_DIR, `${contractName}.json`);
          fs.writeFileSync(abiOutputFile, JSON.stringify(contractData.abi, null, 2));
          
          extractedABIs[contractName] = contractData.abi;
          
          // Placeholder for contract addresses (to be filled after deployment)
          contractAddresses[contractName] = "0x0000000000000000000000000000000000000000";
          
          console.log(`✅ Extracted ABI for ${contractName}`);
        } else {
          console.log(`⚠️  No ABI found for ${contractName}`);
        }
      } else {
        console.log(`❌ Contract file not found: ${contractFile}`);
      }
    } catch (error) {
      console.error(`❌ Error extracting ABI for ${contractName}:`, error.message);
    }
  });

  // Create combined ABIs file
  const combinedABIFile = path.join(OUTPUT_DIR, 'index.js');
  const combinedContent = `// Auto-generated ABI exports
// Generated at: ${new Date().toISOString()}

${Object.entries(extractedABIs).map(([name, abi]) => 
  `export const ${name}ABI = ${JSON.stringify(abi, null, 2)};`
).join('\n\n')}

// Export all ABIs
export const ABIS = {
${Object.keys(extractedABIs).map(name => `  ${name}: ${name}ABI`).join(',\n')}
};
`;

  fs.writeFileSync(combinedABIFile, combinedContent);

  // Create addresses file
  const addressesContent = `// Contract addresses for different networks
// Update these after deployment

export const CONTRACT_ADDRESSES = {
  // Ethereum Mainnet
  1: {
${Object.keys(contractAddresses).map(name => `    ${name}: "${contractAddresses[name]}"`).join(',\n')}
  },
  
  // Ethereum Sepolia Testnet  
  11155111: {
${Object.keys(contractAddresses).map(name => `    ${name}: "${contractAddresses[name]}"`).join(',\n')}
  },
  
  // Polygon Mainnet
  137: {
${Object.keys(contractAddresses).map(name => `    ${name}: "${contractAddresses[name]}"`).join(',\n')}
  },
  
  // Polygon Mumbai Testnet
  80001: {
${Object.keys(contractAddresses).map(name => `    ${name}: "${contractAddresses[name]}"`).join(',\n')}
  },
  
  // Local Development
  31337: {
${Object.keys(contractAddresses).map(name => `    ${name}: "${contractAddresses[name]}"`).join(',\n')}
  }
};

export const getContractAddress = (contractName, chainId) => {
  return CONTRACT_ADDRESSES[chainId]?.[contractName] || null;
};
`;

  fs.writeFileSync(ADDRESSES_FILE, addressesContent);

  console.log(`\n🎉 Successfully extracted ${Object.keys(extractedABIs).length} ABIs!`);
  console.log(`📁 ABIs saved to: ${OUTPUT_DIR}`);
  console.log(`📁 Addresses template saved to: ${ADDRESSES_FILE}`);
  console.log('\n📝 Next steps:');
  console.log('1. Deploy your contracts to get actual addresses');
  console.log('2. Update the addresses in Frontend/src/contracts/addresses.js');
  console.log('3. Run "npm run dev" in the Frontend directory');
}

// Run the extraction
extractABIs();
