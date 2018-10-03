meta:
  title: "Bethesda Archive Format Description version 0x68 (FO3, FNV, TES5)"
  license: MIT
  id: bsa_fo3
  imports:
    - common/bstr
    - common/bzstr

doc-ref: "https://en.uesp.net/wiki/Tes5Mod:Archive_File_Format"

seq:
  - id: header
    type: bsa_header

  - id: folder_records
    type: folder_record
    repeat: expr
    repeat-expr: header.folder_count

instances:
  file_names:
    # TODO: find a way to tie these to their respective file
    type: strz
    repeat: expr
    repeat-expr: header.file_count
    encoding: 'windows-1252'
    if: header.archive_flags.include_file_names
    # our pos is EOF, so we set it to the head of the first file, then jump
    #   back by `total_file_name_length` to the head of the name block
    # this works because `total_file_name_length` also includes the padding
    #   between the end of the name block and the start of file block
    #   even though this isn't actually documented anywhere
    pos: folder_records[0].file_record_block.file_records[0].offset - header.total_file_name_length

types:
  bsa_header:
    meta:
      endian: le
    seq:
      - id: offset
        contents: [0x24, 0x00, 0x00, 0x00]

      - id: archive_flags
        type: archive_flags

      - id: folder_count
        type: u4
      - id: file_count
        type: u4

      - id: total_folder_name_length
        type: u4
      - id: total_file_name_length
        type: u4

      - id: content_flags
        type: content_flags

  archive_flags:
    seq:
      - id: retain_strings_at_startup
        type: b1
      - id: x360_archive
        type: b1
      - id: retain_file_name_offsets
        type: b1
      - id: retain_file_names
        type: b1
      - id: retain_folder_names
        type: b1
      - id: compressed
        type: b1
      - id: include_file_names
        type: b1
      - id: include_folder_names
        type: b1

      # we skip 6 bits b/c bitfields are always big-endian which is backwards
      - id: unused_0
        type: b6
      - id: xmem_compressed
        type: b1
      - id: embed_file_names
        type: b1

      - id: unused_1
        contents: [0x00, 0x00]


  content_flags:
    seq:
      - id: has_fonts
        type: b1
      - id: has_trees
        type: b1
      - id: has_shaders
        type: b1
      - id: has_voices
        type: b1
      - id: has_sounds
        type: b1
      - id: has_menus
        type: b1
      - id: has_textures
        type: b1
      - id: has_meshes
        type: b1

      # we skip 7 bits b/c bitfields are always big-endian which is backwards
      - id: unused_0
        type: b7
      - id: has_misc
        type: b1

      - id: unused_1
        contents: [0x00, 0x00]

  folder_record:
    meta:
      endian:
        switch-on: _root.header.archive_flags.x360_archive
        cases:
          true: be
          false: le
    seq:
      - id: name_hash
        type: u8
      - id: file_count
        type: u4
      - id: file_offset
        type: u4
    instances:
      file_record_block:
        type: file_record_block
        # `file_offset` includes `total_file_name_length` because bethesda
        #   is very smart
        # we subtract it because the file name block comes _after_ the file records
        pos: file_offset - _root.header.total_file_name_length

  file_record_block:
    meta:
      endian:
        switch-on: _root.header.archive_flags.x360_archive
        cases:
          true: be
          false: le
    seq:
      - id: name
        type: bzstr
        if: _root.header.archive_flags.include_folder_names
      - id: file_records
        type: file_record
        repeat: expr
        repeat-expr: _parent.file_count

  file_record:
    meta:
      endian:
        switch-on: _root.header.archive_flags.x360_archive
        cases:
          true: be
          false: le
    seq:
      - id: name_hash
        type: u8
      - id: size_byte
        type: u4
      - id: offset
        type: u4
    instances:
      # for reasons, bit 30 of `size_byte` is used to indicate
      #   if a file is compressed
      size:
        # this sets `size` to `size_byte` with bit 30 as 0
        value: "size_byte & ~0x40000000"
      compressed:
        # a file is compressed if compressed XOR bit 30
        # casting to bool is broken, so we use a ternary instead of XOR
        value: |-
          _root.header.archive_flags.compressed
            ? (size_byte & 0x40000000) == 0
            : (size_byte & 0x40000000) != 0
      file:
        io: _root._io
        type: file
        pos: offset

  file:
    meta:
      endian:
        switch-on: _root.header.archive_flags.x360_archive
        cases:
          true: be
          false: le
    seq:
      - id: name
        type: bstr
        if: _root.header.archive_flags.embed_file_names
      - id: original_size
        type: u4
        if: _parent.compressed
      - id: data
        size: data_size
    instances:
      data_meta_size:
        # if the archive has embedded names, add the
        #   length of the name + 1 (a bstr has a 1-byte prefix)
        # if the file is compressed, add 4 bytes to account
        #   for `original_size`
        value: |-
          (_root.header.archive_flags.embed_file_names
            ? name.str_len + 1
            : 0)
          + (_parent.compressed ? 4 : 0)
      data_size:
        value: _parent.size - data_meta_size
      uncompressed_data:
        if: _parent.compressed and not _root.header.archive_flags.xmem_compressed
        pos: _parent.offset + data_meta_size
        size: data_size
        process: zlib
