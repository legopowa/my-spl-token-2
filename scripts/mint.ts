import * as anchor from '@coral-xyz/anchor'
import { Program } from '@coral-xyz/anchor'
import { SplTokenMinter } from '../target/types/spl_token_minter'
import { PublicKey, SYSVAR_RENT_PUBKEY } from '@solana/web3.js'
import {
    ASSOCIATED_TOKEN_PROGRAM_ID,
    getOrCreateAssociatedTokenAccount,
    TOKEN_PROGRAM_ID,
} from '@solana/spl-token'

// Configure the client to use the local cluster.
const provider = anchor.AnchorProvider.env()
anchor.setProvider(provider)
// Metaplex Constants
const METADATA_SEED = 'metadata'
const TOKEN_METADATA_PROGRAM_ID = new PublicKey(
    'metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s'
)

// Generate a new keypair for the data account for the program
const dataAccount = anchor.web3.Keypair.generate()
// Generate a mint keypair
const mintKeypair = anchor.web3.Keypair.generate()
const wallet = provider.wallet as anchor.Wallet
const connection = provider.connection
console.log('Your wallet address', wallet.publicKey.toString())
const program = anchor.workspace.SplTokenMinter as Program<SplTokenMinter>

// Metadata for the Token
const tokenTitle = 'My Awesome Token'
const tokenSymbol = 'MAT2'
const tokenUri = 'IPFS_URL_OF_JSON_FILE'

const tokenDecimals = 9

const mint = mintKeypair.publicKey
async function deploy() {
    // Initialize data account for the program
    const initTx = await program.methods
        .new()
        .accounts({ dataAccount: dataAccount.publicKey })
        .signers([dataAccount])
        .rpc()
    console.log('Initialization transaction signature', initTx)

    const [metadataAddress] = PublicKey.findProgramAddressSync(
        [
            Buffer.from(METADATA_SEED),
            TOKEN_METADATA_PROGRAM_ID.toBuffer(),
            mint.toBuffer(),
        ],
        TOKEN_METADATA_PROGRAM_ID
    )

    // Create the token mint
    const createTokenMintTx = await program.methods
        .createTokenMint(
            wallet.publicKey, // freeze authority
            tokenDecimals, // decimals
            tokenTitle, // token name
            tokenSymbol, // token symbol
            tokenUri // token uri
        )
        .accounts({
            payer: wallet.publicKey,
            mint: mintKeypair.publicKey,
            metadata: metadataAddress,
            mintAuthority: wallet.publicKey,
            rentAddress: SYSVAR_RENT_PUBKEY,
            metadataProgramId: TOKEN_METADATA_PROGRAM_ID,
        })
        .signers([mintKeypair]) // signing the transaction with the keypair, you actually prove that you have the authority to assign the account to the token program
        .rpc({ skipPreflight: true })
    console.log('Create Token Mint transaction signature', createTokenMintTx)

    // Wallet's associated token account address for mint
    // To learn more about token accounts, check this guide out. https://www.quicknode.com/guides/solana-development/spl-tokens/how-to-look-up-the-address-of-a-token-account#spl-token-accounts
    const tokenAccount = await getOrCreateAssociatedTokenAccount(
        connection,
        wallet.payer, // payer
        mintKeypair.publicKey, // mint
        wallet.publicKey // owner
    )
    const numTokensToMint = new anchor.BN(100)
    const decimalTokens = numTokensToMint.mul(
        new anchor.BN(10).pow(new anchor.BN(tokenDecimals))
    )
    const mintTx = await program.methods
        .mintTo(
            new anchor.BN(decimalTokens) // amount to mint in Lamports unit
        )
        .accounts({
            mintAuthority: wallet.publicKey,
            tokenAccount: tokenAccount.address,
            mint: mintKeypair.publicKey,
        })
        .rpc({ skipPreflight: true })
    console.log('Mint Tokens transaction signature', mintTx)
}

// Run the deployment script
deploy().catch(err => console.error(err))