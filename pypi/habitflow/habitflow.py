#
#  habitflow.py
#  HabitFlow PyPI Wrapper
#
#  Created by Rajnish Singh on 08/06/2026.
#  Copyright © 2026 Rajnish Singh. All rights reserved.
#

import os
import sys
import subprocess
import shutil

def main():
    # Locate package directory where this script and swift source exist
    package_dir = os.path.dirname(os.path.abspath(__file__))
    swift_source = os.path.join(package_dir, "habitflow-cli.swift")
    
    # Store binary in local cache directory to avoid writing in read-only python folders
    cache_dir = os.path.expanduser("~/.habitflow")
    os.makedirs(cache_dir, exist_ok=True)
    binary_path = os.path.join(cache_dir, "habitflow-cli")
    
    needs_compile = False
    if not os.path.exists(binary_path):
        needs_compile = True
    elif os.path.exists(swift_source) and os.path.getmtime(swift_source) > os.path.getmtime(binary_path):
        needs_compile = True
        
    if needs_compile:
        if not shutil.which("swiftc"):
            print("\033[31mError: 'swiftc' compiler not found. Please make sure Command Line Developer Tools are installed.\033[0m")
            print("To install, run in terminal: xcode-select --install")
            sys.exit(1)
            
        print("\033[33mCompiling HabitFlow CLI natively on your Mac...\033[0m")
        result = subprocess.run(["swiftc", swift_source, "-o", binary_path])
        if result.returncode != 0:
            print("\033[31mError: Native compilation failed.\033[0m")
            sys.exit(1)
        print("\033[32mCompilation complete!\033[0m\n")

    # Launch the compiled binary and forward all arguments
    try:
        subprocess.run([binary_path] + sys.argv[1:])
    except KeyboardInterrupt:
        print("\n\033[32mThank you for using HabitFlow. Keep up the consistency!\033[0m\n")

if __name__ == "__main__":
    main()
