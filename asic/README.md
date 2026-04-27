# ASIC Implementation — SNN Conv Core

RTL-to-GDS flow using OpenROAD + SKY130 130nm PDK.

## What's in here

```
asic/
├── src/                      # Synthesis-ready RTL
│   ├── SNN_Conv_Top.sv       # Top wrapper (Conv + Pool)
│   ├── SNN_Accelerator.sv    # $readmemh replaced with localparam ROM
│   ├── AvgPooling.sv         # Unchanged from rtl/
│   ├── LineBuffer.sv         # Unchanged
│   ├── ConvPE.sv             # Unchanged
│   ├── SparsityController.sv # Unchanged
│   ├── TimeStep_FSM.sv       # Unchanged
│   └── Vmem_Array.sv         # Unchanged
├── flow/
│   ├── config.mk             # OpenROAD flow config
│   └── constraint.sdc        # SDC timing constraints
└── scripts/
    └── gen_weights.py        # Converts weights_conv.hex → localparam
```

## Why FC layer is excluded

`FullyConnected.sv` requires 13,520 × 8-bit weights (≈108 KB).
FPGA tools automatically map this to Block RAM.
Standard-cell ASIC synthesis has no equivalent — an SRAM macro
(OpenRAM / DFFRAM) would be required, which is a separate flow.
The Conv+Pool core represents the novel hardware design.

## Setup steps

### 1. Generate conv weights localparam

```bash
python3 asic/scripts/gen_weights.py
```

Paste the output into `asic/src/SNN_Accelerator.sv`,
replacing the placeholder `8'sh00` lines under `CONV_WEIGHTS`.

### 2. Copy unchanged RTL files

```bash
cp rtl/core/AvgPooling.sv       asic/src/
cp rtl/core/ConvPE.sv           asic/src/
cp rtl/core/LineBuffer.sv       asic/src/
cp rtl/core/SparsityController.sv asic/src/
cp rtl/core/TimeStep_FSM.sv     asic/src/
cp rtl/memory/Vmem_Array.sv     asic/src/
```

### 3. Run OpenROAD flow

```bash
# Start Docker container
docker run -it --platform linux/amd64 \
  -v /path/to/OpenROAD-flow-scripts:/OpenROAD-flow-scripts \
  -w /OpenROAD-flow-scripts \
  openroad/flow-ubuntu22.04-builder:latest bash

# Inside container — copy design files
cp -r /path/to/274FINAL_2.0/asic \
  flow/designs/sky130hd/snn_conv

# Run step by step
cd flow
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk synth
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk floorplan
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk place
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk cts
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk route
make DESIGN_CONFIG=./designs/sky130hd/snn_conv/flow/config.mk finish
```

### 4. Read results

```bash
cat flow/reports/sky130hd/snn_conv/base/6_final_timing.rpt | grep "worst slack"
cat flow/reports/sky130hd/snn_conv/base/6_final_area.rpt
cat flow/reports/sky130hd/snn_conv/base/6_final_power.rpt
```
