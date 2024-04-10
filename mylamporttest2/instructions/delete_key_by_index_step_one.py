from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.system_program import ID as SYS_PROGRAM_ID
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class DeleteKeyByIndexStepOneArgs(typing.TypedDict):
    nextpkh: list[int]
    keyindex: int


layout = borsh.CStruct("nextpkh" / borsh.U8[32], "keyindex" / borsh.U64)


class DeleteKeyByIndexStepOneAccounts(typing.TypedDict):
    data_account: Pubkey
    submitter: Pubkey


def delete_key_by_index_step_one(
    args: DeleteKeyByIndexStepOneArgs,
    accounts: DeleteKeyByIndexStepOneAccounts,
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
    identifier = b"\xb4\x80\xf728\x9f`\x84"
    encoded_args = layout.build(
        {
            "nextpkh": args["nextpkh"],
            "keyindex": args["keyindex"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
