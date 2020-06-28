# SIN_GEN

SIN wave generator for FPGA

## Interface

| Name             | I/O  | P/N  | Description                          |
| ---------------- | ---- | ---- | ------------------------------------ |
| RESET_n          | I    | N    | Reset                                |
| CLK              | I    | P    | Clock                                |
| ASI_READY        | O    | P    | Avalon-ST sink data ready            |
| ASI_VALID        | I    | P    | Avalon-ST sink data valid            |
| ASI_DATA[DW-1:0] | I    | P    | Avalon-ST sink data: Frequency ratio |
| ASO_VALID        | O    | P    | Avalon-ST source data valid          |
| ASO_DATA[DW-1:0] | O    | P    | Avalon-ST source data: SIN wave      |
| ASO_ERROR        | O    | P    | Avalon-ST source error               |

`DW` is Data width parameter.

## License

MIT License

## Author

[toms74209200](<https://github.com/toms74209200>)