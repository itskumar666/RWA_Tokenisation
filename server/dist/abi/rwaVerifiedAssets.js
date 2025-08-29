export const rwaVerifiedAssetsAbi = [
    {
        type: 'function',
        name: 'registerVerifiedAsset',
        stateMutability: 'nonpayable',
        inputs: [
            { name: 'owner', type: 'address' },
            { name: 'response', type: 'bytes' },
        ],
        outputs: [],
    },
    {
        type: 'function',
        name: 'DeRegisterVerifiedAsset',
        stateMutability: 'nonpayable',
        inputs: [
            { name: 'owner', type: 'address' },
            { name: 'assetId', type: 'uint256' },
        ],
        outputs: [],
    },
    {
        type: 'function',
        name: 'upDateAssetValue',
        stateMutability: 'nonpayable',
        inputs: [
            { name: 'owner', type: 'address' },
            { name: 'assetId', type: 'uint256' },
            { name: 'newValueInUSD', type: 'uint256' },
            { name: 'isLocked', type: 'bool' },
            { name: 'tradable', type: 'bool' },
        ],
        outputs: [],
    },
    // Views
    {
        type: 'function',
        name: 'getVerifiedAssets',
        stateMutability: 'view',
        inputs: [
            { name: 'owner', type: 'address' },
        ],
        outputs: [
            {
                name: '',
                type: 'tuple[]',
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
        name: 'isOwnerAllowed',
        stateMutability: 'view',
        inputs: [{ name: '_owner', type: 'address' }],
        outputs: [{ name: '', type: 'bool' }],
    },
    {
        type: 'function',
        name: 'addMember',
        stateMutability: 'nonpayable',
        inputs: [{ name: 'newMember', type: 'address' }],
        outputs: [],
    },
    {
        type: 'function',
        name: 'removeMember',
        stateMutability: 'nonpayable',
        inputs: [{ name: 'member', type: 'address' }],
        outputs: [],
    },
];
