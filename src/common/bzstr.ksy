meta:
  license: MIT
  id: bzstr

doc: Null-terminated string with 1-byte length prefix

seq:
  - id: str_len
    type: u1
  - id: str
    type: strz
    size: str_len
    encoding: windows-1252
