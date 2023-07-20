#!/bin/bash
#This is a script for generating the tests logs and also for verification of the results

# Step 1: Check if the required arguments are provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <linker_file> <asm_test_file>"
  exit 1
fi

# Step 2: Extract the linker file and assembly test file from the command-line arguments
linker_file="$1"
asm_test_file="$2"


# Step 2: Compile the file
echo "Compiling the file..."
riscv32-unknown-elf-gcc -march=rv32gc -mabi=ilp32 -nostdlib -T "$linker_file" "$asm_test_file" -o test.elf
echo "Compilation completed."

#step 3: Generate the log File and also add a timeout to avoid the infinite generation of log file.
echo "Log file Generation Started"
timeout 5s riscv_sim_RV32 test.elf > sail.log
exit_code=$?

if [ $exit_code -eq 124 ]; then
  echo "Error! Infinite Log Generation Found:: Correct the code and recompile."
fi

echo "Log File Generation Completed"
~                                                           
