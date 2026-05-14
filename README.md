# SCOMP ADC Peripheral

A Quartus-based FPGA project that extends the SCOMP teaching processor with a memory-mapped ADC peripheral for the LTC2308. The design lets SCOMP assembly programs start conversions, poll status, select input channels, and read 12-bit sampled data through custom I/O registers.

This repository includes the hardware design, sample assembly programs, build artifacts, and supporting course deliverables used for development and testing on a Cyclone V platform.

## Highlights

- Added a custom `ADC_PERIPHERAL` VHDL module with a simple memory-mapped register interface.
- Integrated the ADC peripheral into the `SCOMP_System` top-level Quartus design.
- Implemented SPI-style control for the LTC2308 ADC, including conversion start, wait, shift, and data capture.
- Wrote example SCOMP assembly programs for ADC readback and a small two-channel analog combination lock demo.
- Included generated `.sof` programming files and project documentation for reference.

## Repository Layout

```text
.
|-- ADCTest/               Main Quartus project
|-- preliminary/           Early design files and checkpoints
|-- Deliverables/          Class deliverables and diagrams
|-- SOF-Anson/             Generated programming output
|-- SOF-Seonwoo/           Generated programming output
|-- game.asm               Demo assembly program
|-- AssemblyTest.txt       Simple ADC test program
`-- README.md
```

## Important Files

- `ADCTest/ADC_Peripheral.vhd`: custom ADC peripheral implementation
- `ADCTest/SCOMP.vhd`: SCOMP processor core
- `ADCTest/SCOMP_System.bdf`: top-level block design
- `ADCTest/SCOMP.qpf` / `ADCTest/SCOMP.qsf`: Quartus project files
- `game.asm`: demo program using ADC input as a two-step analog lock
- `AssemblyTest.txt`: simple ADC read/display test program
- `SOF-Anson/SCOMP.sof` and `SOF-Seonwoo/SCOMP.sof`: compiled programming outputs

## ADC Register Map

The peripheral exposes four memory-mapped I/O addresses:

- `0xC0` - control register
- `0xC1` - status register
- `0xC2` - sampled ADC data
- `0xC3` - selected ADC channel

The register decode and bus behavior are implemented in `ADCTest/ADC_Peripheral.vhd`.

## Toolchain

- Intel Quartus Prime Lite
- Cyclone V target device: `5CSXFC6D6F31C6`
- VHDL for hardware modules
- SCOMP assembly / `.mif` files for test programs

Included Quartus reports in `ADCTest/output_files/` show a successful compile for revision `SCOMP`.

## Notes

- `ADCTest/` contains both source files and Quartus-generated build outputs.
- `ADCTest.zip` is preserved as a packaged snapshot of the project.
- The current folder layout is mostly kept in its original form; this README is meant to make it easier to browse without heavily restructuring the project.
