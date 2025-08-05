// // Layout of Contract:
// // version
// // imports
// // interfaces, libraries, contracts
// // errors
// // Type declarations
// // State variables
// // Events
// // Modifiers
// // Functions

// // Layout of Functions:
// // constructor
// // receive function (if exists)
// // fallback function (if exists)
// // external
// // public
// // internal
// // private
// // view & pure functions

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
// import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
// import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
// import {RWA_Types} from "./RWA_Types.sol";
// /**
//  * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
//  * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
//  * DO NOT USE THIS CODE IN PRODUCTION.
//  */
// contract RWA_Verification is FunctionsClient, ConfirmedOwner {
//     using FunctionsRequest for FunctionsRequest.Request;

//     bytes32 public s_lastRequestId;
//     RWA_Types.RWA_Info public s_lastResponse;
//     bytes public s_lastError;
//     uint256 public s_requestId;
//     mapping(uint256 s_requestId => bool) public s_requestResponses;
//     mapping(uint256 s_requestId => RWA_Types.RWA_Info s_lastResponse ) public s_requestResponsesData;

//     error UnexpectedRequestID(bytes32 requestId);

//     event Response(uint256 indexed s_requestId,  RWA_Types.RWA_Info s_lastResponse, bytes err);

//     constructor(
//         address rwa_Types,
//         address router
//     ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
      
//     }

//     /**
//      * @notice Send a simple request
//      * @param source JavaScript source code
//      * @param encryptedSecretsUrls Encrypted URLs where to fetch user secrets
//      * @param donHostedSecretsSlotID Don hosted secrets slotId
//      * @param donHostedSecretsVersion Don hosted secrets version
//      * @param args List of arguments accessible from within the source code
//      * @param bytesArgs Array of bytes arguments, represented as hex strings
//      * @param subscriptionId Billing ID
//      */
//     function sendRequest(
//         string memory source,
//         bytes memory encryptedSecretsUrls,
//         uint8 donHostedSecretsSlotID,
//         uint64 donHostedSecretsVersion,
//         string[] memory args,
//         bytes[] memory bytesArgs,
//         uint64 subscriptionId,
//         uint32 gasLimit,
//         bytes32 donID
//     ) external onlyOwner returns (bytes32 requestId) {

//         FunctionsRequest.Request memory req;
//         req.initializeRequestForInlineJavaScript(source);
//         if (encryptedSecretsUrls.length > 0)
//             req.addSecretsReference(encryptedSecretsUrls);
//         else if (donHostedSecretsVersion > 0) {
//             req.addDONHostedSecrets(
//                 donHostedSecretsSlotID,
//                 donHostedSecretsVersion
//             );
//         }
//         if (args.length > 0) req.setArgs(args);
//         if (bytesArgs.length > 0) req.setBytesArgs(bytesArgs);
//         s_lastRequestId = _sendRequest(
//             req.encodeCBOR(),
//             subscriptionId,
//             gasLimit,
//             donID
//         );
//         return s_lastRequestId;
//     }

//     /**
//      * @notice Send a pre-encoded CBOR request
//      * @param request CBOR-encoded request data
//      * @param subscriptionId Billing ID
//      * @param gasLimit The maximum amount of gas the request can consume
//      * @param donID ID of the job to be invoked
//      * @return requestId The ID of the sent request
//      */
//     function sendRequestCBOR(
//         bytes memory request,
//         uint64 subscriptionId,
//         uint32 gasLimit,
//         bytes32 donID
//     ) external onlyOwner returns (bytes32 requestId) {
//         s_lastRequestId = _sendRequest(
//             request,
//             subscriptionId,
//             gasLimit,
//             donID
//         );
//         return s_lastRequestId;
//     }

//     /**
//      * @notice Store latest result/error
//      * @param requestId The request ID, returned by sendRequest()
//      * @param response Aggregated response from the user code
//      * @param err Aggregated error from the user code or from the execution pipeline
//      * Either response or error parameter will be set, but never both
//      */
//     function fulfillRequest(
//         bytes32 requestId,
//         bytes memory response,
//         bytes memory err
//     ) internal override {
//         if (s_lastRequestId != requestId) {
//             revert UnexpectedRequestID(requestId);
//         }
//         if(response.length == 0 && err.length == 0) {
//             revert("RWA_Verification: Response and error cannot both be empty");
//         }
//         if(err.length>0){
//             revert("RWA_Verification: Error received in fulfillRequest");
//         }
//         s_requestId = uint256(requestId);
//         s_requestResponses[s_requestId] = true;
//         s_lastError = err;
//          (uint8 assetType_, string memory assetName_, uint256 assetId_, bool isLocked_, uint256 valueInUSD_,address owner_) =
//         abi.decode(response, (uint8, string, uint256, bool, uint256,address));

//     // Store in s_lastResponse
//     s_lastResponse = RWA_Types.RWA_Info({
//         assetType: RWA_Types.assetType(assetType_), // Cast uint8 to enum
//         assetName: assetName_,
//         assetId: assetId_,
//         isLocked: isLocked_,
//         isVerified: true, // Assuming the asset is verified if this function is called
//         valueInUSD: valueInUSD_,
//         owner: owner_ ,
//         tradable: true // Assuming the asset is tradable if this function is called
//     });
//      s_requestResponsesData[s_requestId] = s_lastResponse;

//         emit Response(s_requestId, s_lastResponse, s_lastError);
//     }
// }


