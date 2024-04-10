from __future__ import annotations
import typing
from solders.pubkey import Pubkey
from solders.system_program import ID as SYS_PROGRAM_ID
from solders.instruction import Instruction, AccountMeta
import borsh_construct as borsh
from ..program_id import PROGRAM_ID


class VerifyWithBytes32Args(typing.TypedDict):
    bits: list[int]
    sig: list[bytes]
    pub: list[list[list[int]]]


layout = borsh.CStruct(
    "bits" / borsh.U8[32], "sig" / borsh.Bytes[256], "pub" / borsh.U8[32][2][256]
)
class VerifyWithBytes32Accounts(typing.TypedDict):
    data_account: Pubkey

def verify_with_bytes32(
    args: VerifyWithBytes32Args,
    accounts: VerifyWithBytes32Accounts,
    program_id: Pubkey = PROGRAM_ID,
    remaining_accounts: typing.Optional[typing.List[AccountMeta]] = None,
) -> Instruction:
    keys: list[AccountMeta] = [
        AccountMeta(pubkey=SYS_PROGRAM_ID, is_signer=False, is_writable=False)
    ]
    if remaining_accounts is not None:
        keys += remaining_accounts
    identifier = b"\x9e\xc5\\\x0c\xf7g\xf0\x18"
    encoded_args = layout.build(
        {
            "bits": args["bits"],
            "sig": args["sig"],
            "pub": args["pub"],
        }
    )
    data = identifier + encoded_args
    return Instruction(program_id, data, keys)
