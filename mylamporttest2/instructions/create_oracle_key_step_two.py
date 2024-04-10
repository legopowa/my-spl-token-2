from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.system_program import ID as SYS_PROGRAM_ID
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class CreateOracleKeyStepTwoArgs(typing.TypedDict):
    nextpkh: list[int]
    neworaclepkh: list[int]


layout = borsh.CStruct("nextpkh" / borsh.U8[32], "neworaclepkh" / borsh.U8[32])


class CreateOracleKeyStepTwoAccounts(typing.TypedDict):
    data_account: Pubkey
    submitter: Pubkey


def create_oracle_key_step_two(
    args: CreateOracleKeyStepTwoArgs,
    accounts: CreateOracleKeyStepTwoAccounts,
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
    identifier = b"\xb3\x8f\xff&%a;("
    encoded_args = layout.build(
        {
            "nextpkh": args["nextpkh"],
            "neworaclepkh": args["neworaclepkh"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
