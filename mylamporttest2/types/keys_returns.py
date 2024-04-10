from __future__ import annotations
from . import key_type
import typing
from dataclasses import dataclass
from construct import Container
import borsh_construct as borsh


class keys_returnsJSON(typing.TypedDict):
    key_type: key_type.KeyTypeJSON
    pkh: list[int]


@dataclass
class keys_returns:
    layout: typing.ClassVar = borsh.CStruct(
        "key_type" / key_type.layout, "pkh" / borsh.U8[32]
    )
    key_type: key_type.KeyTypeKind
    pkh: list[int]

    @classmethod
    def from_decoded(cls, obj: Container) -> "keys_returns":
        return cls(key_type=key_type.from_decoded(obj.key_type), pkh=obj.pkh)

    def to_encodable(self) -> dict[str, typing.Any]:
        return {"key_type": self.key_type.to_encodable(), "pkh": self.pkh}

    def to_json(self) -> keys_returnsJSON:
        return {"key_type": self.key_type.to_json(), "pkh": self.pkh}

    @classmethod
    def from_json(cls, obj: keys_returnsJSON) -> "keys_returns":
        return cls(key_type=key_type.from_json(obj["key_type"]), pkh=obj["pkh"])
