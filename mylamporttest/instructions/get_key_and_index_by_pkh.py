from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class GetKeyAndIndexByPkhArgs(typing.TypedDict):
    #pkh: list[int]
    pkh: Pubkey


layout = borsh.CStruct("pkh" / borsh.U8[32])


class GetKeyAndIndexByPkhAccounts(typing.TypedDict):
    data_account: Pubkey


def get_key_and_index_by_pkh(
    args: GetKeyAndIndexByPkhArgs,
    accounts: GetKeyAndIndexByPkhAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=False)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\xa17\x8f\xa4dj\xc7\x94"
    encoded_args = layout.build(
        {
            "pkh": args["pkh"].to_bytes(),
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
