from solana.transaction import Transaction
from solders.keypair import Keypair
from solders.pubkey import Pubkey
from anchorpy import Provider
from mylamporttest2.instructions import get_key_and_index_by_pkh

 # call an instruction
account = Keypair()
hex_string = "0xb7b18ded9664d1a8e923a5942ec1ca5cd8c13c40eb1a5215d5800600f5a587be"
bytes32_value = bytes.fromhex(hex_string[2:].zfill(64))
ix = get_key_and_index_by_pkh({
  "pkh": bytes32_value
}, {
  "signer": account.pubkey(), # signer
  "data_account": account.pubkey()#Pubkey("agcxtXCrjjDc1uAXwMZ5v9wRpt1P1HrNoLwzpajYiD4"),
})
tx_result = Transaction().add(ix)
#for log in tx_result['result']['meta']['logMessages']:
#    print(log)
# Specify the pkh as a Pubkey object
# Call the function with the specified pkh
#result = get_key_and_index_by_pkh({"pkh": pkh}, {"data_account": some_pubkey})
print(tx_result)
#print(f"Key Type: {result.keyType}, PKH: {result.pkh}, Index: {result.index}")