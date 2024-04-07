import asyncio
from anchorpy import create_workspace, close_workspace, Context
from solders.system_program import ID as SYS_PROGRAM_ID
from solders.pubkey import Pubkey
from solders.keypair import Keypair
from solders.sysvar import RENT
TOKEN_PROGRAM_ID = Pubkey.from_string("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
ASSOCITAED_TOKEN_PROGRAM_ID = Pubkey.from_string("FFxjv61p5USpF6PntTJ8AQgMLybjFwCVgyzwGxUsSZXh")

# Create a Mint keypair. This will be our token mint.
mint = Keypair()

async def main():
    # Read the deployed program from the workspace.
    workspace = create_workspace()
    # The program from the workspace we want to use
    program = workspace["spl_token_minter"]

    # Close all HTTP clients in the workspace.
    await close_workspace(workspace)
    print(program.rpc)
    create_token = await program.rpc["create_token"](ctx=Context(accounts={
        "mint": mint.pubkey(),
        "signer": program.provider.wallet.payer.pubkey(),
        "system_program": SYS_PROGRAM_ID,
        "rent": RENT,
        "token_program": TOKEN_PROGRAM_ID
    }, signers=[program.provider.wallet.payer, mint]))

    print("Create token signature: ", create_token)
    associated_token_account_pubkey, nonce = Pubkey.find_program_address([bytes(program.provider.wallet.payer.pubkey()), bytes(TOKEN_PROGRAM_ID), bytes(mint.pubkey())], ASSOCITAED_TOKEN_PROGRAM_ID)
    create_associated_token_account = await program.rpc["create_associated_token_account"](ctx=Context(accounts={
        "mint": mint.pubkey(),
        "token_account" : associated_token_account_pubkey,
        "signer": program.provider.wallet.payer.pubkey(),
        "system_program": SYS_PROGRAM_ID,
        "rent": RENT,
        "token_program": TOKEN_PROGRAM_ID,
        "associated_token_program" : ASSOCITAED_TOKEN_PROGRAM_ID
    }, signers=[program.provider.wallet.payer]))
    print("Create associated token account signature: ", create_associated_token_account)

    mint_token = await program.rpc["mint_token"](1000, ctx=Context(accounts={
        "mint": mint.pubkey(),
        "recipient" : associated_token_account_pubkey,
        "signer": program.provider.wallet.payer.pubkey(),
        "system_program": SYS_PROGRAM_ID,
        "rent": RENT,
        "token_program": TOKEN_PROGRAM_ID,
    }, signers=[program.provider.wallet.payer]))

    print("Mint token signature: ", mint_token)

asyncio.run(main())

