#!/bin/bash

BIN_DIR="build/release/tui/basics"
PASSED=0
FAILED=0

# Ensure the directory exists
if [ ! -d "$BIN_DIR" ]; then
    echo "Error: Directory $BIN_DIR does not exist. Run 'make release' first."
    exit 1
fi

echo "Initiating strict exit code validation..."
echo "----------------------------------------"

# Loop through all executable files in the directory
for bin in "$BIN_DIR"/*; do
    if [ -f "$bin" ] && [ -x "$bin" ]; then
        
        # We pipe a simulated Enter key (echo "") to prevent I/O locks.
        # > /dev/null 2>&1 completely silences both standard output and errors.
        echo "" | "$bin" > /dev/null 2>&1
        
        # Capture the exit code immediately
        EXIT_CODE=$?
        
        # Evaluate
        if [ $EXIT_CODE -ne 0 ]; then
            echo "[FAIL] $(basename "$bin") -> Exit Code: $EXIT_CODE"
            FAILED=$((FAILED + 1))
        else
            echo "[ OK ] $(basename "$bin") -> Exit Code: 0"
            PASSED=$((PASSED + 1))
        fi
    fi
done

echo "----------------------------------------"
echo "Results: $PASSED passed, $FAILED failed."

# Propagate the final script exit code based on the test results
if [ $FAILED -ne 0 ]; then
    exit 1
else
    exit 0
fi