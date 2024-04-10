from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from ..program_id import PROGRAM_ID


class NewAccounts(typing.TypedDict):
    data_account: Pubkey


def new(
    accounts: NewAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=True)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\x87,\xcd\xc6\x19\x01H\xbc"
    encoded_args = b""
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
