# SCOMP ADC Peripheral

This was a course project where we added an ADC peripheral to the SCOMP processor and integrated it into the Quartus project. The ADC is memory-mapped, so SCOMP programs can choose a channel, start a conversion, wait until it finishes, and read the sampled value back through I/O.

The main custom logic is in `ADCTest/ADC_Peripheral.vhd`. The full Quartus project is in `ADCTest/`.

## What is in here

- `ADCTest/`: main Quartus project
- `preliminary/`: earlier design files and checkpoints
- `Deliverables/`: slides, diagrams, and other class submission material
- `SOF-Build-1/` and `SOF-Build-2/`: compiled `.sof` files
- `game.asm`: demo program that uses ADC input in a simple two-step lock
- `AssemblyTest.txt`: basic ADC test program

## Important files

- `ADCTest/ADC_Peripheral.vhd`: ADC peripheral implementation
- `ADCTest/SCOMP_System.bdf`: top-level system diagram
- `ADCTest/SCOMP.qpf` and `ADCTest/SCOMP.qsf`: Quartus project files
- `ADCTest/output_files/`: generated Quartus reports and build outputs

## ADC register map

The peripheral uses these I/O addresses:

- `0xC0`: control
- `0xC1`: status
- `0xC2`: ADC data
- `0xC3`: channel select

In the control/status flow, the program writes the channel, starts a conversion, polls the ready bit, and then reads the 12-bit sample.

## Notes

- The folder structure is mostly the original project layout.
- `ADCTest/` includes both source files and Quartus-generated files.
- `ADCTest.zip` is just a packaged copy of the project.
