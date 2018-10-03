BSA KSY
=======

## Building
TODO: set up cmake

Until i have cmake set up, you can build with ksc:
```sh
mkdir build
kaitai-struct-compiler -t <your language here> -d=build/ src/<the parser you want>.ksy
```

## Supported Formats
  - [ ] BSA
    - [ ] TES4
    - [x] FO3/FNV/TES5
    - [ ] SSE
    - [ ] FO4
  - [ ] BA2
    - [ ] GNRL
    - [ ] DX10
  - maybe others in future (plugins maybe?)
