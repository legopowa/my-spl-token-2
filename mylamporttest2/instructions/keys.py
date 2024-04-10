from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class KeysArgs(typing.TypedDict):
    arg0: int


layout = borsh.CStruct("arg0" / borsh.U128)


class KeysAccounts(typing.TypedDict):
    data_account: Pubkey


def keys(
    args: KeysArgs,
    accounts: KeysAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=False)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\x16>\xe2\x9d<\xa1\xff\xb3"
    encoded_args = layout.build(
        {
            "arg0": args["arg0"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
