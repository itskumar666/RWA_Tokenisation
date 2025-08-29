export const rwaManagerAbi = [
    {
        type: 'function',
        name: 'depositRWAAndMintNFT',
        stateMutability: 'payable',
        inputs: [
            { name: '_requestId', type: 'uint256' },
            { name: '_assetValue', type: 'uint256' },
            { name: '_assetOwner', type: 'address' },
            { name: '_tokenURI', type: 'string' },
        ],
        outputs: [],
    },
    {
        type: 'function',
        name: 'depositRWAAndMintNFTWithProof',
        stateMutability: 'payable',
        inputs: [
            { name: '_requestId', type: 'uint256' },
            { name: '_assetValue', type: 'uint256' },
            { name: '_assetOwner', type: 'address' },
            { name: '_tokenURI', type: 'string' },
            { name: 'signature', type: 'bytes' },
        ],
        outputs: [],
    },
    {
        type: 'function',
        name: 'setBackendSigner',
        stateMutability: 'nonpayable',
        inputs: [{ name: '_signer', type: 'address' }],
        outputs: [],
    },
    // view helpers
    {
        type: 'function',
        name: 'getUserAssetInfo',
        stateMutability: 'view',
        inputs: [
            { name: '_user', type: 'address' },
            { name: '_requestId', type: 'uint256' },
        ],
        outputs: [
            {
                type: 'tuple',
                components: [
                    { name: 'assetType', type: 'uint8' },
                    { name: 'assetName', type: 'string' },
                    { name: 'assetId', type: 'uint256' },
                    { name: 'isLocked', type: 'bool' },
                    { name: 'isVerified', type: 'bool' },
                    { name: 'valueInUSD', type: 'uint256' },
                    { name: 'owner', type: 'address' },
                    { name: 'tradable', type: 'bool' },
                ],
            },
        ],
    },
    {
        type: 'function',
        name: 'getUserRWAInfoagainstRequestId',
        stateMutability: 'view',
        inputs: [{ name: 'assetId', type: 'uint256' }],
        outputs: [
            {
                type: 'tuple',
                components: [
                    { name: 'assetType', type: 'uint8' },
                    { name: 'assetName', type: 'string' },
                    { name: 'assetId', type: 'uint256' },
                    { name: 'isLocked', type: 'bool' },
                    { name: 'isVerified', type: 'bool' },
                    { name: 'valueInUSD', type: 'uint256' },
                    { name: 'owner', type: 'address' },
                    { name: 'tradable', type: 'bool' },
                ],
            },
        ],
    },
];
