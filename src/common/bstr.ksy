meta:
  license: MIT
  id: bstr

doc: String with 1-byte length prefix

seq:
  - id: str_len
    type: u1
  - id: str
    type: str
    size: str_len
    encoding: windows-1252
