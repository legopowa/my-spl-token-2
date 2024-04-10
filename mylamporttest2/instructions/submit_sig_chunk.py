from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class SubmitSigChunkArgs(typing.TypedDict):
    chunk: list[bytes]
    chunksize: int


layout = borsh.CStruct("chunk" / borsh.Bytes[32], "chunksize" / borsh.U64)


class SubmitSigChunkAccounts(typing.TypedDict):
    data_account: Pubkey
    submitter: Pubkey


def submit_sig_chunk(
    args: SubmitSigChunkArgs,
    accounts: SubmitSigChunkAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=True),
        AccountMeta(pubkey=accounts["submitter"], is_signer=True, is_writable=False),
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\xbbr\x0f\x1e\xef)J\x0c"
    encoded_args = layout.build(
        {
            "chunk": args["chunk"],
            "chunksize": args["chunksize"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
