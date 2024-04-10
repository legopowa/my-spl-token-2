from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from .. import types
from ..program_id import PROGRAM_ID


class GetPkHsByPrivilegeArgs(typing.TypedDict):
    privilege: types.key_type.KeyTypeKind


layout = borsh.CStruct("privilege" / types.key_type.layout)


class GetPkHsByPrivilegeAccounts(typing.TypedDict):
    data_account: Pubkey


def get_pk_hs_by_privilege(
    args: GetPkHsByPrivilegeArgs,
    accounts: GetPkHsByPrivilegeAccounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=accounts["data_account"], is_signer=False, is_writable=False)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\xa09\x8f\xa1\xac\x8ebu"
    encoded_args = layout.build(
        {
            "privilege": args["privilege"].to_encodable(),
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
