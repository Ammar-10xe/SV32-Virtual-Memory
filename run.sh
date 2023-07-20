#!/bin/bash
#This is a script for generating the tests logs and also for verification of the results

# Default values for the flags
run_sail=false
run_spike=false

# Step 1: Check if the required arguments are provided
if [ $# -lt 3 ]; then
  echo "Usage: $0 [-sail] [-spike] <linker_file> <asm_test_file>"
  exit 1
fi

# Step 2: Use while loop to parse the flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -sail)
      run_sail=true
      ;;
    -spike)
      run_spike=true
      ;;
    *)
      break
      ;;
  esac
  shift
done

# Step 3: Extract the linker file and assembly test file from the command-line arguments
linker_file="$1"
asm_test_file="$2"

# Step 4: Compile the file
echo "Compiling the file..."
riscv32-unknown-elf-gcc -march=rv32gc -mabi=ilp32 -nostdlib -T "$linker_file" "$asm_test_file" -o test.elf
echo "Compilation completed."

# Step 5: Generate the log file for Sail
if [ "$run_sail" = true ]; then
  echo "Log file Generation for Sail Started"
  timeout 2s riscv_sim_RV32 test.elf > sail.log 2>/dev/null
  exit_code=$?

  if [ $exit_code -eq 124 ]; then
    echo "Error! Infinite Log Generation Found: Correct the code and recompile."
  fi

  echo "Log File Generation for Sail Completed"
fi

# Step 6: Generate the log file for Spike
if [ "$run_spike" = true ]; then
  echo "Log File Generation for Spike Started"
  timeout 2s spike -d --isa=RV32gc test.elf 1>spike.out 2>spike.log &
  spike_pid=$!

  # Wait for the background process to complete and get the exit code
  wait $spike_pid
  exit_code=$?
  
  if [ $exit_code -eq 124 ]; then
    echo "Error! Infinite Log Generation Found: Correct the code and recompile."
  fi

  echo "Log File Generation for Spike Completed"
fi

