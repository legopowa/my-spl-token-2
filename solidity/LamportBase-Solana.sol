// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

contract LamportBase2 {

    bool initialized = false;
    bool public lastVerificationResult;

    // Define different key types
    enum KeyType { MASTER, ORACLE, DELETED }

    // Store the keys and their corresponding pkh
    struct Key {
        KeyType keyType;
        bytes32 pkh;
    }

    Key[] public keys; // For iteration
    mapping(bytes32 => Key) public keyData; // For search
    bytes32 constant master1 = 0xb7b18ded9664d1a8e923a5942ec1ca5cd8c13c40eb1a5215d5800600f5a587be; // default keyfile has these
    bytes32 constant master2 = 0x1ed304ab73e124b0b99406dfa1388a492a818837b4b41ce5693ad84dacfc3f25;
    bytes32 constant oracle = 0xd62569e61a6423c880a429676be48756c931fe0519121684f5fb05cbd17877fa; 

    event WrongKeyType(bytes32 pkh, string message);  // Event declaration
    event LogLastCalculatedHash(uint256 hash);
    event VerificationFailed(uint256 hashedData);
    event PkhUpdated(KeyType keyType, bytes32 previousPKH, bytes32 newPKH);
    event KeyAdded(KeyType keyType, bytes32 newPKH);
    event KeyModified(KeyType originalKeyType, bytes32 originalPKH, bytes32 modifiedPKH, KeyType newKeyType);

    // Initial setup of the Lamport system, providing the first MASTER keys and an ORACLE key
    // function init(bytes32 masterPKH1, bytes32 masterPKH2, bytes32 oraclePKH) public {
    //     require(!initialized, "LamportBase: Already initialized");

    //     ;
    // }
    constructor () {
    
        addKey(KeyType.MASTER, master1);
        addKey(KeyType.MASTER, master2);
        addKey(KeyType.ORACLE, oracle);
        initialized = true;
    }

    struct AccumulatedData {
        bytes32[2][256] currentpub;
        bytes[256] sig;
        uint256 currentPubIndex;
        uint256 sigIndex;
    }

    // Mapping to store data for each signer
    mapping(address => AccumulatedData) private pendingValidations;

    // Function to submit chunks of the 'currentpub' data
    // @signer(submitter)
    // function submitCurrentPubChunk(bytes32[2][16] calldata chunk, uint256 chunkSize) external {
    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
    //     submitterKey = tx.accounts.submitter.key;
    //     require(chunkSize <= 16, "Chunk size is too large");
    //     for (uint256 i = 0; i < chunkSize; i++) {
    //         require(data.currentPubIndex < 256, "Index out of bounds");
    //         data.currentpub[data.currentPubIndex++] = chunk[i];
    //     }
    // }
    @signer(submitter)
    function submitCurrentPubChunk(bytes32[2][16] calldata chunk, uint256 chunkSize) external {
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
        submitterKey = tx.accounts.submitter.key;  // Update the global variable with the current submitter's key

        if (chunkSize > 16) {
            wipeAccumulatedData();  // Cleanup before reverting if the chunk size is too large
            revert("Chunk size is too large");
        }

        for (uint256 i = 0; i < chunkSize; i++) {
            if (data.currentPubIndex >= 256) {
                wipeAccumulatedData();  // Cleanup before reverting if index is out of bounds
                revert("Index out of bounds");
            }
            data.currentpub[data.currentPubIndex++] = chunk[i];
        }
    }
    // Function to submit chunks of the 'sig' data
    // @signer(submitter)
    // function submitSigChunk(bytes[32] calldata chunk, uint256 chunkSize) external {
    //     require(chunkSize <= 32, "Chunk size is too large");
    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
    //     for (uint256 i = 0; i < chunkSize; i++) {
    //         require(data.sigIndex < 256, "Index out of bounds");
    //         data.sig[data.sigIndex++] = chunk[i];
    //     }
    // }

    @signer(submitter)
    function submitSigChunk(bytes[32] calldata chunk, uint256 chunkSize) external {
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
        submitterKey = tx.accounts.submitter.key;  // Update the global variable with the current submitter's key

        if (chunkSize > 32) {
            wipeAccumulatedData();  // Cleanup before reverting if the chunk size is too large
            revert("Chunk size is too large");
        }

        for (uint256 i = 0; i < chunkSize; i++) {
            if (data.sigIndex >= 256) {
                wipeAccumulatedData();  // Cleanup before reverting if index is out of bounds
                revert("Index out of bounds");
            }
            data.sig[data.sigIndex++] = chunk[i];
        }
    }
    // Function to wipe accumulated data for a user
    // @signer(submitter)
    // function wipeAccumulatedData() public {
    //     delete pendingValidations[tx.accounts.submitter.key];
    // }
    address public submitterKey;

    function wipeAccumulatedData() private {
        delete pendingValidations[submitterKey];
        submitterKey = address(0);
    }
    // Function to perform onlyLamportMaster checks
    // function performLamportMasterCheck(
    //     bytes32[2][256] calldata currentpub,
    //     bytes[256] calldata sig,
    //     bytes32 nextPKH,
    //     bytes memory prepacked
    // ) public returns (bool) {
    //     require(initialized, "LamportBase: not initialized");

    //     bytes32 pkh = keccak256(abi.encodePacked(currentpub));
    //     if (keyData[pkh].keyType != KeyType.MASTER) {
    //         return false;
    //     }

    //     uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
    //     bool verificationResult = verify_u256(hashedData, sig, currentpub);

    //     if (!verificationResult) {
    //         return false;
    //     } else {
    //         updateKey(pkh, nextPKH);
    //         return true;
    //     }
    // }
    // lamport 'verify' logic
    function verify_u256(
        uint256 bits,
        bytes[256] calldata sig,
        bytes32[2][256] calldata pub
    ) public pure returns (bool) {
        unchecked {
            for (uint256 i = 0; i < 256; i++) {
                if (
                    pub[i][((bits & (1 << (255 - i))) > 0) ? 1 : 0] !=
                    keccak256(sig[i])
                ) return false;
            }

            return true;
        }
    }
    function updateKey(bytes32 oldPKH, bytes32 newPKH) internal {
        require(keyData[oldPKH].pkh != 0, "LamportBase: No such key");

        // Update the public key hash in the key data mapping
        Key memory updatedKey = Key(keyData[oldPKH].keyType, newPKH);
        keyData[newPKH] = updatedKey;

        // Remove the old key from key data
        delete keyData[oldPKH];

        // Update the public key hash in the keys array
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i].pkh == oldPKH) {
                keys[i] = updatedKey;
                break;
            }
        }

        emit PkhUpdated(updatedKey.keyType, oldPKH, newPKH);
    }
    @signer(submitter)
    function performLamportMasterCheck(bytes32 nextPKH, bytes memory prepacked) external returns (bool) {
        require(initialized, "LamportBase: not initialized");
        submitterKey = tx.accounts.submitter.key;
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

        bytes32 pkh = keccak256(abi.encodePacked(data.currentpub));
        if (keyData[pkh].keyType != KeyType.MASTER) {
            emit WrongKeyType(pkh, "Attempted action with non-master key");  // Emitting the event
            wipeAccumulatedData();
            return false;
        }

        uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
        emit LogLastCalculatedHash(hashedData);

        bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);

        if (!verificationResult) {
            wipeAccumulatedData();
            emit VerificationFailed(hashedData);
            return false;
        } else {
            updateKey(pkh, nextPKH);
            wipeAccumulatedData();
            return true;
        }
    }

    function performLamportMasterCheckInternal(bytes32 nextPKH, bytes memory prepacked) internal returns (bool) {
        require(initialized, "LamportBase: not initialized");
        AccumulatedData storage data = pendingValidations[submitterKey];
        //submitterKey = tx.accounts.submitter.key;

        bytes32 pkh = keccak256(abi.encodePacked(data.currentpub));
        if (keyData[pkh].keyType != KeyType.MASTER) {
            emit WrongKeyType(pkh, "Attempted action with non-master key");  // Emitting the event
            wipeAccumulatedData();
            return false;
        }

        uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
        emit LogLastCalculatedHash(hashedData);

        bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);

        if (!verificationResult) {
            wipeAccumulatedData();
            emit VerificationFailed(hashedData);
            return false;
        } else {
            updateKey(pkh, nextPKH);
            wipeAccumulatedData();
            return true;
        }
    }

    // // Function to perform onlyLamportOracle checks
    // function performLamportOracleCheck(
    //     bytes32[2][256] calldata currentpub,
    //     bytes[256] calldata sig,
    //     bytes32 nextPKH,
    //     bytes memory prepacked
    // ) public returns (bool) {
    //     require(initialized, "LamportBase: not initialized");

    //     bytes32 pkh = keccak256(abi.encodePacked(currentpub));
    //     if (keyData[pkh].keyType != KeyType.ORACLE) {
    //         return false;
    //     }

    //     uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
    //     bool verificationResult = verify_u256(hashedData, sig, currentpub);

    //     if (!verificationResult) {
    //         return false;
    //     } else {
    //         updateKey(pkh, nextPKH);
    //         return true;
    //     }
    // }
    @signer(submitter)
    function performLamportOracleCheck(bytes32 nextPKH, bytes memory prepacked) external returns (bool) {
        require(initialized, "LamportBase: not initialized");
        submitterKey = tx.accounts.submitter.key;

        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

        bytes32 pkh = keccak256(abi.encodePacked(data.currentpub));
        if (keyData[pkh].keyType != KeyType.ORACLE) {
            emit WrongKeyType(pkh, "Attempted action with non-oracle key");  // Emitting the event
            wipeAccumulatedData();
            return false;
        }

        uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
        emit LogLastCalculatedHash(hashedData);
        bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);

        if (!verificationResult) {
            wipeAccumulatedData();
            emit VerificationFailed(hashedData);
            return false;
        } else {
            wipeAccumulatedData();
            updateKey(pkh, nextPKH);
            return true;
        }
    }
    // Add a new key
    function addKey(KeyType keyType, bytes32 newPKH) private {
        Key memory newKey = Key(keyType, newPKH);
        keys.push(newKey);
        keyData[newPKH] = newKey;
        emit KeyAdded(keyType, newPKH);
    }

    // Search for a key by its PKH, return the key and its position in the keys array
    function getKeyAndIndexByPKH(bytes32 pkh) public view returns (KeyType, bytes32, uint) {
        Key memory key = keyData[pkh];
        require(key.pkh != 0, "LamportBase: No such key");

        // Iterate over keys array to find the position
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i].pkh == pkh) {
                return (key.keyType, key.pkh, i);
            }
        }
        revert("LamportBase: No such key");
    }
    function getPKHsByPrivilege(KeyType privilege) public view returns (bytes32[] memory) {
        bytes32[] memory pkhs = new bytes32[](keys.length);
        uint counter = 0;

        for (uint i = 0; i < keys.length; i++) {
            if (keys[i].keyType == privilege) {
                pkhs[counter] = keys[i].pkh;
                counter++;
            }
        }

        // Prepare the array to return
        bytes32[] memory result = new bytes32[](counter);
        for(uint i = 0; i < counter; i++) {
            result[i] = pkhs[i];
        }

        return result;
    }

    // Delete a key
    // function deleteKey(bytes32 firstMasterPKH, bytes32 secondMasterPKH, bytes32 targetPKH) private {
    //     // Check that the two provided keys are master keys
    //     require(keyData[firstMasterPKH].keyType == KeyType.MASTER && keyData[secondMasterPKH].keyType == KeyType.MASTER, "LamportBase: Provided keys are not master keys");

    //     // Disallow master keys from deleting themselves
    //     require(targetPKH != firstMasterPKH && targetPKH != secondMasterPKH, "LamportBase: Master keys cannot delete themselves");

    //     require(keyData[targetPKH].pkh != 0, "LamportBase: No such key");
    //     for (uint i = 0; i < keys.length; i++) {
    //         if (keys[i].pkh == targetPKH) {
    //             delete keyData[targetPKH];
    //             keys[i] = keys[keys.length - 1];
    //             keys.pop();
    //             emit KeyDeleted(keys[i].keyType, targetPKH);
    //             break;
    //         }
    //     }
    // }

    bytes32 private lastUsedDeleteKeyHash;
    uint256 private lastUsedDeleteKeyIndex;
    bytes32 private storedNextPKH;
    @signer(submitter)
    function deleteKeyByIndexStepOne(
        bytes32 nextPKH,
        uint256 keyIndex
    )
        external

    {
        bytes memory prepacked = abi.encodePacked(keyIndex);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }
        // Save the used deleteKeyHash in a global variable
        lastUsedDeleteKeyIndex = keyIndex;
        storedNextPKH = nextPKH;
        wipeAccumulatedData();

    }

    @signer(submitter)
    function deleteKeyByIndexStepTwo(
        bytes32 nextPKH,
        uint256 keyIndex
    )
        external
    {
        bytes memory prepacked = abi.encodePacked(keyIndex);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }

        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
        bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
        if (currentPKH == storedNextPKH) {
            wipeAccumulatedData();
            revert("LamportBase: Cannot use the same keychain twice for this function");
        }

        if (lastUsedDeleteKeyIndex != keyIndex) {
            wipeAccumulatedData();
            revert("LamportBase: Keys do not match");
        }

        if (keyIndex >= keys.length) {
            wipeAccumulatedData();
            revert("LamportBase: Invalid key index");
        }

        Key memory keyToDelete = keys[keyIndex];
        if (keyToDelete.keyType == KeyType.DELETED) {
            wipeAccumulatedData();
            revert("LamportBase: Key already deleted");
        }

        KeyType originalKeyType = keyToDelete.keyType;
        bytes32 modifiedPKH = 0xde1e7ed000000000000000000000000000000000000000000000000000000000;
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.number)));
        modifiedPKH ^= bytes32(randomValue); // XOR to keep "de1e7ed" in the first 7 characters

        keys[keyIndex].pkh = modifiedPKH;
        keys[keyIndex].keyType = KeyType.DELETED;
        keyData[modifiedPKH] = keys[keyIndex];
        delete keyData[keyToDelete.pkh];

        emit KeyModified(originalKeyType, keyToDelete.pkh, modifiedPKH, KeyType.DELETED);

        // Reset the tracking variables
        lastUsedDeleteKeyIndex = 0;
        storedNextPKH = bytes32(0);
        wipeAccumulatedData();
    }


    // @signer(submitter)
    // function deleteKeyByIndexStepTwo(
    //     bytes32 nextPKH,
    //     uint256 keyIndex
    // )
    //     external
    // {
    //     bytes memory prepacked = abi.encodePacked(keyIndex);
    //     submitterKey = tx.accounts.submitter.key;

    //     bool lamportCheckPassed = performLamportMasterCheckInternal(
    //         nextPKH, 
    //         prepacked
    //     );

    //     if (!lamportCheckPassed) {
    //         wipeAccumulatedData(); // Cleanup function before reverting
    //         revert("Lamport Master validation failed");
    //     }

    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];
    //     bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
    //     if (currentPKH == storedNextPKH) {
    //         wipeAccumulatedData();
    //         revert("LamportBase: Cannot use the same keychain twice for this function");
    //     }

    //     if (lastUsedDeleteKeyIndex != keyIndex) {
    //         wipeAccumulatedData();
    //         revert("LamportBase: Keys do not match");
    //     }

    //     if (keyIndex >= keys.length) {
    //         wipeAccumulatedData();
    //         revert("LamportBase: Invalid key index");
    //     }

    //     Key memory keyToDelete = keys[keyIndex];
    //     if (keyToDelete.keyType == KeyType.DELETED) {
    //         wipeAccumulatedData();
    //         revert("LamportBase: Key already deleted");
    //     }

    //     KeyType originalKeyType = keyToDelete.keyType;
    //     bytes32 modifiedPKH = 0xde1e7ed000000000000000000000000000000000000000000000000000000000;
    //     uint256 randomValue = uint256(keccak256(abi.encodePacked(block.number)));
    //     modifiedPKH ^= bytes32(randomValue); // XOR to keep "de1e7ed" in the first 7 characters

    //     keys[keyIndex].pkh = modifiedPKH;
    //     keys[keyIndex].keyType = KeyType.DELETED;
    //     keyData[modifiedPKH] = keys[keyIndex];
    //     delete keyData[keyToDelete.pkh];

    //     emit KeyModified(originalKeyType, keyToDelete.pkh, modifiedPKH, KeyType.DELETED);

    //     // Reset the tracking variables
    //     lastUsedDeleteKeyIndex = 0;
    //     storedNextPKH = bytes32(0);
    //     wipeAccumulatedData();
    // }
    // @signer(submitter)
    // function deleteKeyByIndexStepTwo(
    //     bytes32 nextPKH,
    //     uint256 keyIndex
    // )
    //     external

    // {
    //     bytes memory prepacked = abi.encodePacked(keyIndex);
    //     submitterKey = tx.accounts.submitter.key;

    //     bool lamportCheckPassed = performLamportMasterCheckInternal(
    //         nextPKH, 
    //         prepacked
    //     );

    //     if (!lamportCheckPassed) {
    //         wipeAccumulatedData(); // Cleanup function before reverting
    //         revert("Lamport Master validation failed");
    //     }
    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

    //     // Calculate the current public key hash (currentPKH)


    //     bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
    //     // Check if storedNextPKH is not the same as the current PKH
    //     require(currentPKH != storedNextPKH, "LamportBase: Cannot use the same keychain twice for this function");
        
    //     // Check if the used keyIndex matches the last used keyIndex
    //     require(lastUsedDeleteKeyIndex == keyIndex, "LamportBase: Keys do not match");
        
    //     // Check if the keyIndex is valid
    //     require(keyIndex < keys.length, "LamportBase: Invalid key index");

    //     // Proceed with key deletion logic
    //     Key memory keyToDelete = keys[keyIndex];
    //     require(keyToDelete.keyType != KeyType.DELETED, "LamportBase: Key already deleted");

    //     // Store the original KeyType
    //     KeyType originalKeyType = keyToDelete.keyType;
    //     //bytes32 blockHash = blockhash(block.number - 1); // Solana's equivalent might be different

    //     // Overwrite the first 7 characters with "de1e7ed" and the rest with random values
    //     bytes32 modifiedPKH = 0xde1e7ed000000000000000000000000000000000000000000000000000000000;
    //     uint256 randomValue = uint256(keccak256(abi.encodePacked(block.number)));
    //     modifiedPKH ^= bytes32(randomValue); // XOR to keep "de1e7ed" in the first 7 characters

    //     // Modify the existing entry instead of deleting it
    //     keys[keyIndex].pkh = modifiedPKH;
    //     keys[keyIndex].keyType = KeyType.DELETED;

    //     // Update the keyData mapping
    //     keyData[modifiedPKH] = keys[keyIndex];
    //     delete keyData[keyToDelete.pkh];

    //     emit KeyModified(originalKeyType, keyToDelete.pkh, modifiedPKH, KeyType.DELETED);

    //     // Reset the tracking variables
    //     lastUsedDeleteKeyIndex = 0;
    //     storedNextPKH = bytes32(0);
    //     wipeAccumulatedData();

    // }

    @signer(submitter)
    function deleteKeyByPKHStepOne(
        bytes32 nextPKH,
        bytes32 deleteKeyHash
    )
        external

    {
        bytes memory prepacked = abi.encodePacked(deleteKeyHash);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }
        // Save the used deleteKeyHash in a global variable
        lastUsedDeleteKeyHash = deleteKeyHash;
        storedNextPKH = nextPKH;
        wipeAccumulatedData();

    }
    @signer(submitter)
    function deleteKeyByPKHStepTwo(
        bytes32 nextPKH,
        bytes32 confirmDeleteKeyHash
    )
        external

    {
        bytes memory prepacked = abi.encodePacked(confirmDeleteKeyHash);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }
        // Calculate the current public key hash (currentPKH)
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

        bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
        // Check if storedNextPKH is not the same as the current PKH
        require(currentPKH != storedNextPKH, "LamportBase: Cannot use the same keychain twice for this function");
        
        // Check if the used deleteKeyHash matches the last used deleteKeyHash
        require(lastUsedDeleteKeyHash == confirmDeleteKeyHash, "LamportBase: Keys do not match");
        
        // Execute the delete key logic
        // Assuming firstMasterPKH and secondMasterPKH are correctly verified and provided
        bytes32 firstMasterPKH = storedNextPKH; // Placeholder, replace with the actual value
        bytes32 secondMasterPKH = currentPKH; // Placeholder, replace with the actual value
        bytes32 targetPKH = confirmDeleteKeyHash;
        
        // Check that the two provided keys are master keys
        require(keyData[firstMasterPKH].keyType == KeyType.MASTER && keyData[secondMasterPKH].keyType == KeyType.MASTER, "LamportBase: Provided keys are not master keys");
        
        // Disallow master keys from deleting themselves
        require(targetPKH != firstMasterPKH && targetPKH != secondMasterPKH, "LamportBase: Master keys cannot delete themselves");
        
        // require(keyData[targetPKH].pkh != 0, "LamportBase: No such key (deletion)");
        // for (uint i = 0; i < keys.length; i++) {
        //     if (keys[i].pkh == targetPKH) {
        //         delete keyData[targetPKH];
        //         keys[i] = keys[keys.length - 1];
        //         keys.pop();
        //         emit KeyDeleted(keys[i].keyType, targetPKH);
        //         break;
        //     }
        // }
        require(keyData[targetPKH].pkh != 0, "LamportBase: No such key (deletion)");
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i].pkh == targetPKH) {

                KeyType originalKeyType = keyData[targetPKH].keyType; // Store the original KeyType
                // Overwriting the first 7 characters with "de1e7ed" and the rest with random values
                bytes32 modifiedPKH = 0xde1e7ed000000000000000000000000000000000000000000000000000000000;
                //uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
                uint256 randomValue = uint256(keccak256(abi.encodePacked(block.number)));
                
                
                modifiedPKH ^= bytes32(randomValue); // XOR to keep "de1e7ed" in the first 7 characters
                
                // Modify the existing entry instead of deleting it
                keyData[targetPKH].pkh = modifiedPKH;
                keyData[targetPKH].keyType = KeyType.DELETED; // Set the keyType to DELETED
                
                emit KeyModified(originalKeyType, targetPKH, modifiedPKH, KeyType.DELETED); // Emitting a new event for modification                    
                break;
            }
        }


        
        // Reset lastUsedDeleteKeyHash
        lastUsedDeleteKeyHash = bytes32(0);
        storedNextPKH = bytes32(0);
        wipeAccumulatedData();

    }




//     //@signer(submitter)
//     // modifier onlyLamportMaster(bytes32 nextPKH, bytes memory prepacked) {
//     //     require(initialized, "LamportBase: not initialized");
//     //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

//     //     bytes32 pkh = keccak256(abi.encodePacked(currentpub));
//     //     if (keyData[pkh].keyType != KeyType.MASTER) {
//     //         wipeAccumulatedData(tx.accounts.submitter.key); // Wipe data before reverting if not a master key
//     //         revert("LamportBase: Not a master key");
//     //     }
//     //     uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
//     //     emit LogLastCalculatedHash(hashedData);

//     //     bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);

//     //     lastVerificationResult = verificationResult;

//     //     if (!verificationResult) {
//     //         emit VerificationFailed(hashedData);
//     //         wipeAccumulatedData(tx.accounts.submitter.key);
//     //         revert("LamportBase: Verification failed");
//     //     } else {
//     //         emit PkhUpdated(keyData[pkh].keyType, pkh, nextPKH);
//     //         //wipeAccumulatedData(tx.accounts.submitter.key);
//     //         updateKey(pkh, nextPKH);
//     //     }

//     //     _;
//     // }
//     modifier onlyLamportMaster(address submitter, bytes32 nextPKH, bytes memory prepacked) {
//         require(initialized, "LamportBase: not initialized");
//         AccumulatedData storage data = pendingValidations[submitter];
//         submitterKey = submitter;
//         bytes32 pkh = keccak256(abi.encodePacked(data.currentpub));
//         if (keyData[pkh].keyType != KeyType.MASTER) {
//             wipeAccumulatedData();
//             revert("LamportBase: Not a master key");
//         }

//         uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
//         emit LogLastCalculatedHash(hashedData);

//         bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);
//         lastVerificationResult = verificationResult;

//         if (!verificationResult) {
//             emit VerificationFailed(hashedData);
//             wipeAccumulatedData();
//             revert("LamportBase: Verification failed");
//         } else {
//             //emit PkhUpdated(keyData[pkh].keyType, pkh, nextPKH);
//             updateKey(pkh, nextPKH);
//         }

//         _;
//     }
//     // function updateKey(bytes32 oldPKH, bytes32 newPKH) internal {
//     //     require(keyData[oldPKH].pkh != 0, "LamportBase: No such key");
//     //     keyData[oldPKH].pkh = newPKH; // Update the public key hash in the key data mapping
//     //     emit PkhUpdated(keyData[oldPKH].keyType, oldPKH, newPKH);
//     // }




    // //@signer(submitter)
    // modifier onlyLamportOracle(address submitter, bytes32 nextPKH, bytes memory prepacked) {
    //     require(initialized, "LamportBase: not initialized");
    //     AccumulatedData storage data = pendingValidations[submitter];
    //     submitterKey = submitter;

    //     bytes32 pkh = keccak256(abi.encodePacked(data.currentpub));
    //     if (keyData[pkh].keyType != KeyType.ORACLE) {
    //         wipeAccumulatedData(); // Wipe data before reverting if not an oracle key
    //         revert("LamportBase: Not an oracle key");
    //     }

    //     uint256 hashedData = uint256(keccak256(abi.encodePacked(prepacked, nextPKH)));
    //     emit LogLastCalculatedHash(hashedData);

    //     bool verificationResult = verify_u256(hashedData, data.sig, data.currentpub);
    //     lastVerificationResult = verificationResult;

    //     if (!verificationResult) {
    //         emit VerificationFailed(hashedData);
    //         wipeAccumulatedData();
    //         revert("LamportBase: Verification failed");
    //     } else {
    //         //emit PkhUpdated(keyData[pkh].keyType, pkh, nextPKH);
    //         updateKey(pkh, nextPKH);
    //     }

    //     _; // Proceed with the execution of the function that the modifier is applied to
    // }


    bytes32 public lastUsedNextPKH;
    // @signer(submitter)
    // function createMasterKeyStepOne(
    //     bytes32 nextPKH,
    //     bytes32 newmasterPKH
    // )
    //     external
    //     onlyLamportMaster(
    //         nextPKH,
    //         abi.encodePacked(newmasterPKH)
    //     )
    // {
    //     // Save the used master NextPKH in a global variable
    //     lastUsedNextPKH = nextPKH;
    //     wipeAccumulatedData(tx.accounts.submitter.key);
    // }
    @signer(submitter)
    function createMasterKeyStepOne(
        bytes32 nextPKH,
        bytes32 newmasterPKH
    ) external 
    {
        bytes memory prepacked = abi.encodePacked(newmasterPKH);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }
        lastUsedNextPKH = nextPKH;
        wipeAccumulatedData();
    }
    @signer(submitter)
    function createMasterKeyStepTwo(
        bytes32 nextPKH,
        bytes32 newmasterPKH
    )
        external
    {
        bytes memory prepacked = abi.encodePacked(newmasterPKH);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }

        // Retrieve accumulated data for the submitter
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

        // Calculate the current public key hash
        bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
        // Check if the current PKH matches the last used PKH
        if (lastUsedNextPKH == currentPKH) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("LamportBase: PKH matches last used PKH (use separate second key)");
        }

        // All checks pass, proceed to add the new master key
        addKey(KeyType.MASTER, newmasterPKH);

        // Reset tracking variables after successful operation
        lastUsedNextPKH = bytes32(0);
        wipeAccumulatedData();
    }

    // @signer(submitter)
    // function createMasterKeyStepTwo(
    //     bytes32 nextPKH,
    //     bytes32 newmasterPKH
    // )
    //     external

    // {
    //     bytes memory prepacked = abi.encodePacked(newmasterPKH);
    //     submitterKey = tx.accounts.submitter.key;

    //     bool lamportCheckPassed = performLamportMasterCheckInternal(
    //         nextPKH, 
    //         prepacked
    //     );

    //     if (!lamportCheckPassed) {
    //         wipeAccumulatedData(); // Cleanup function before reverting
    //         revert("Lamport Master validation failed");
    //     }
    //     // Check if the used master NextPKH matches the last used PKH

    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

    //     bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
    //     bool pkhMatched = (lastUsedNextPKH != currentPKH);
    //     //require(lastUsedNextPKH != nextPKH, "LamportBase: Same master key is being used again, need a separate one");
    //     lastUsedNextPKH = bytes32(0);
    //     // If checks pass, add the new master key
    //     require(pkhMatched, "LamportBase: PKH matches last used PKH (use separate second key)");

    //     addKey(KeyType.MASTER, newmasterPKH);

    //     // Reset lastUsedNextPKH
    //     wipeAccumulatedData();
    //     lastUsedNextPKH = bytes32(0);
    // }
    @signer(submitter)
    function createOracleKeyStepOne(
        bytes32 nextPKH,
        bytes32 newOraclePKH
    )
        external

    {
        bytes memory prepacked = abi.encodePacked(newOraclePKH);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }
        wipeAccumulatedData();
        lastUsedNextPKH = nextPKH;
        

    }
    @signer(submitter)
    function createOracleKeyStepTwo(
        bytes32 nextPKH,
        bytes32 newOraclePKH
    )
        external
    {
        bytes memory prepacked = abi.encodePacked(newOraclePKH);
        submitterKey = tx.accounts.submitter.key;

        bool lamportCheckPassed = performLamportMasterCheckInternal(
            nextPKH, 
            prepacked
        );

        if (!lamportCheckPassed) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("Lamport Master validation failed");
        }

        // Access the accumulated data for this submitter
        AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

        // Calculate the current public key hash from the accumulated data
        bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
        
        // Ensure the PKH does not match the last used PKH to prevent replay
        if (lastUsedNextPKH == currentPKH) {
            wipeAccumulatedData(); // Cleanup function before reverting
            revert("LamportBase: PKH matches last used PKH (use separate second key)");
        }

        // All checks pass, proceed to add the new Oracle key
        addKey(KeyType.ORACLE, newOraclePKH);

        // Reset tracking variables after operation
        lastUsedNextPKH = bytes32(0);
        wipeAccumulatedData();
    }

    // @signer(submitter)
    // function createOracleKeyStepTwo(
    //     bytes32 nextPKH,
    //     bytes32 newOraclePKH
    // )
    //     external

    // {
    //     bytes memory prepacked = abi.encodePacked(newOraclePKH);
    //     submitterKey = tx.accounts.submitter.key;

    //     bool lamportCheckPassed = performLamportMasterCheckInternal(
    //         nextPKH, 
    //         prepacked
    //     );

    //     if (!lamportCheckPassed) {
    //         wipeAccumulatedData(); // Cleanup function before reverting
    //         revert("Lamport Master validation failed");
    //     }
    //     AccumulatedData storage data = pendingValidations[tx.accounts.submitter.key];

    //     bytes32 currentPKH = keccak256(abi.encodePacked(data.currentpub));
    //     bool pkhMatched = (lastUsedNextPKH != currentPKH);
    //     //require(lastUsedNextPKH != nextPKH, "LamportBase: Same master key is being used again, need a separate one");
    //     lastUsedNextPKH = bytes32(0);
    //     // If checks pass, add the new master key
    //     require(pkhMatched, "LamportBase: PKH matches last used PKH (use separate second key)");

    //     addKey(KeyType.ORACLE, newOraclePKH);

    //     // Reset lastUsedNextPKH
    //     wipeAccumulatedData();
    //     lastUsedNextPKH = bytes32(0);
    // }

}

