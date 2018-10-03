meta:
  title: "Bethesda Archive Format Description"
  license: MIT
  id: bsa
  file-extension: bsa
  imports:
    - bsa_fo3

enums:
  version:
    # # version 67 is used by TES4
    # 0x67: tes4
    # version 68 is used by FO3, FNV, and TES5
    0x68: fo3
    # # version 69 (nice) is used by SSE
    # 0x69: sse
    # # version 01 is used by FO4
    # 0x01: fo4

seq:
  - id: fileid
    contents: [0x42, 0x53, 0x41, 0x00]
  - id: version
    type: u4le
    enum: version
  - id: archive
    type:
      switch-on: version
      cases:
        # "version::tes4": bsa_tes4
        "version::fo3": bsa_fo3
        # "version::sse": bsa_sse
        # "version::fo4": bsa_fo4s
