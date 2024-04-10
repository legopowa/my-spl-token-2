from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.system_program import ID as SYS_PROGRAM_ID
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class PerformLamportOracleCheckArgs(typing.TypedDict):
    nextpkh: list[int]
    prepacked: bytes


layout = borsh.CStruct("nextpkh" / borsh.U8[32], "prepacked" / borsh.Bytes)


class PerformLamportOracleCheckAccounts(typing.TypedDict):
    data_account: Pubkey
    submitter: Pubkey


def perform_lamport_oracle_check(
    args: PerformLamportOracleCheckArgs,
    accounts: PerformLamportOracleCheckAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=True),
        AccountMeta(pubkey=accounts["submitter"], is_signer=True, is_writable=False),
        AccountMeta(pubkey=SYS_PROGRAM_ID, is_signer=False, is_writable=False),
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"[\xd5\xba^\r\xf0\xee\xf2"
    encoded_args = layout.build(
        {
            "nextpkh": args["nextpkh"],
            "prepacked": args["prepacked"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
