
# SV32-Virtual-Memory

This repository is dedicated to testing the SV32 Virtual Memory address translation. We have created a variety of tests located in the tests folder to ensure the robustness and reliability of the system.

## Prerequisites
Before you can run the tests, you need to have the following tools installed:

1. RISC-V Toolchain: This is a set of tools to compile and debug RISC-V programs. You can download it from [here](https://github.com/riscv-collab/riscv-gnu-toolchain).

2. Spike Simulator: Spike is the official RISC-V ISA Simulator. It provides full system emulation or proxied emulation with HTIF/FESVR. You can download it from [here](https://github.com/riscv-software-src/riscv-isa-sim).

3. Sail Simulator: Sail is a language for describing the semantics of instruction set architectures (ISAs), and tools for generating emulators, theorem proving tools, etc. from these descriptions. You can download it from [here](https://github.com/riscv/sail-riscv).

__Additionally, create a folder named "logs" in the root directory of this repository. The logs of each test run will be generated inside this folder.__

## Running the Tests
To run the tests, we have provided a script `run.sh`. You can execute this script with the `-sail` or `-spike` flag to choose the simulator you want to use. You also need to provide the linker file and the path for the test you want to run.

Here is an example of how to run a test using the Sail simulator:

```bash
./run.sh -sail linker.ld tests/test1
```

Or, if you want to use the Spike simulator:

```bash
./run.sh -spike linker.ld tests/test1
```
Please replace linker.ld and tests/test1 with your actual linker file and test path.

During the test run, the logs for the test will be generated in the "logs" folder, and the terminal will display whether the run has passed or failed.

## Contributing
We welcome contributions! Please feel free to submit a pull request or open an issue if you find any bugs or have any suggestions to improve the system.
