
# 32-bit UART ALU

This project implements an FPGA ALU that can perform 32-bit addition (`add32()`), multiplication (`mul32()`), and division (`div32`) over UART.

## Dependencies

IPs (git submodules, run `git submodule update --init --recursive` to load after cloning):

* <https://github.com/alexforencich/verilog-uart>
* <https://github.com/bespoke-silicon-group/basejump_stl>

Toolchain:

* <https://github.com/YosysHQ/oss-cad-suite-build/releases>
* <https://github.com/zachjs/sv2v/releases>


## Usage
This project is primarily built to target the iCEBreaker v1.0 FPGA. Run synthesis, implementation, place and route, and program the board by running `make icestorm_icebreaker_program`.
After programming the board, use either the sample Python code in `main.py` or a serial monitor (like `minicom`) to communicate with the board. The packet format is as follows:

| Frame        | Field          | Description                               |
|--------------|----------------|-------------------------------------------|
| 0            | Opcode         | Specifies the operation                   |
| 1            | Reserved       | Reserved for future use                   |
| 2            | Length (LSB)   | Least significant byte of the data length |
| 3            | Length (MSB)   | Most significant byte of the data length  |
| 4-(Length-1) | Data           | Data with specified length                |

The available operations and their opcodes are below:

| Opcode |          Operation         |
|--------|----------------------------|
| `0x10` | `add32(op1, op2, ..., opN) |
| `0x11` | `mul32(op1, op2, ..., opN) |
| `0x12` | `div32(dividend, divisor)  |


## Misc. Information

* Baud rate: 115200 Hz
* Clock frequency (PLL output): 33.178 MHz
