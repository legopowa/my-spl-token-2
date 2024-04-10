// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract SolanaExample {
    // Declare state variables
    uint256 public data;

    // Constructor with payer annotation
    @payer(payerAccount)
    constructor() {
        data = 0;
    }

    // Function to update data with a mutable account and signer
    @mutableAccount(dataAccount) @signer(authorizedSigner)
    function updateData(uint256 newData) external {
        require(tx.accounts.authorizedSigner.is_signer, "Unauthorized: Signer must sign the transaction");
        data = newData; // Assuming 'data' is stored in 'dataAccount' which is mutable
    }

    // Function to read data using a read-only account
    @account(dataAccount)
    function readData() external view returns (uint256) {
        return data; // Read from a read-only account
    }
}
