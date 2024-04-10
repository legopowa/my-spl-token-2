from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
from ..program_id import PROGRAM_ID


class LastUsedNextPkhAccounts(typing.TypedDict):
    data_account: Pubkey


def last_used_next_pkh(
    accounts: LastUsedNextPkhAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=False)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\x94\xfaa\x1aA\xdf@."
    encoded_args = b""
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
