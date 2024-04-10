from __future__ import annotations
from . import key_type
import typing
from dataclasses import dataclass
from construct import Container
import borsh_construct as borsh


class getKeyAndIndexByPKH_returnsJSON(typing.TypedDict):
    return_0: key_type.KeyTypeJSON
    return_1: list[int]
    return_2: int


@dataclass
class getKeyAndIndexByPKH_returns:
    layout: typing.ClassVar = borsh.CStruct(
        "return_0" / key_type.layout, "return_1" / borsh.U8[32], "return_2" / borsh.U64
    )
    return_0: key_type.KeyTypeKind
    return_1: list[int]
    return_2: int

    @classmethod
    def from_decoded(cls, obj: Container) -> "getKeyAndIndexByPKH_returns":
        return cls(
            return_0=key_type.from_decoded(obj.return_0),
            return_1=obj.return_1,
            return_2=obj.return_2,
        )

    def to_encodable(self) -> dict[str, typing.Any]:
        return {
            "return_0": self.return_0.to_encodable(),
            "return_1": self.return_1,
            "return_2": self.return_2,
        }

    def to_json(self) -> getKeyAndIndexByPKH_returnsJSON:
        return {
            "return_0": self.return_0.to_json(),
            "return_1": self.return_1,
            "return_2": self.return_2,
        }

    @classmethod
    def from_json(
        cls, obj: getKeyAndIndexByPKH_returnsJSON
    ) -> "getKeyAndIndexByPKH_returns":
        return cls(
            return_0=key_type.from_json(obj["return_0"]),
            return_1=obj["return_1"],
            return_2=obj["return_2"],
        )
