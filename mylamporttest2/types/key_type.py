from __future__ import annotations
import typing
from dataclasses import dataclass
from anchorpy.borsh_extension import EnumForCodegen
import borsh_construct as borsh


class MASTERJSON(typing.TypedDict):
    kind: typing.Literal["MASTER"]


class ORACLEJSON(typing.TypedDict):
    kind: typing.Literal["ORACLE"]


class DELETEDJSON(typing.TypedDict):
    kind: typing.Literal["DELETED"]


@dataclass
class MASTER:
    discriminator: typing.ClassVar = 0
    kind: typing.ClassVar = "MASTER"

    @classmethod
    def to_json(cls) -> MASTERJSON:
        return MASTERJSON(
            kind="MASTER",
        )

    @classmethod
    def to_encodable(cls) -> dict:
        return {
            "MASTER": {},
        }


@dataclass
class ORACLE:
    discriminator: typing.ClassVar = 1
    kind: typing.ClassVar = "ORACLE"

    @classmethod
    def to_json(cls) -> ORACLEJSON:
        return ORACLEJSON(
            kind="ORACLE",
        )

    @classmethod
    def to_encodable(cls) -> dict:
        return {
            "ORACLE": {},
        }


@dataclass
class DELETED:
    discriminator: typing.ClassVar = 2
    kind: typing.ClassVar = "DELETED"

    @classmethod
    def to_json(cls) -> DELETEDJSON:
        return DELETEDJSON(
            kind="DELETED",
        )

    @classmethod
    def to_encodable(cls) -> dict:
        return {
            "DELETED": {},
        }


KeyTypeKind = typing.Union[MASTER, ORACLE, DELETED]
KeyTypeJSON = typing.Union[MASTERJSON, ORACLEJSON, DELETEDJSON]


def from_decoded(obj: dict) -> KeyTypeKind:
    if not isinstance(obj, dict):
        raise ValueError("Invalid enum object")
    if "MASTER" in obj:
        return MASTER()
    if "ORACLE" in obj:
        return ORACLE()
    if "DELETED" in obj:
        return DELETED()
    raise ValueError("Invalid enum object")


def from_json(obj: KeyTypeJSON) -> KeyTypeKind:
    if obj["kind"] == "MASTER":
        return MASTER()
    if obj["kind"] == "ORACLE":
        return ORACLE()
    if obj["kind"] == "DELETED":
        return DELETED()
    kind = obj["kind"]
    raise ValueError(f"Unrecognized enum kind: {kind}")


layout = EnumForCodegen(
    "MASTER" / borsh.CStruct(), "ORACLE" / borsh.CStruct(), "DELETED" / borsh.CStruct()
)
