#!/usr/bin/env python3
"""Run Robot from the template root, forwarding all Robot CLI arguments."""
import os
import sys
from pathlib import Path


def main():
    try:
        from robot import run_cli
    except ImportError:
        print('Install dependencies first: python -m pip install -r requirements.txt', file=sys.stderr)
        return 2
    os.chdir(Path(__file__).resolve().parent)
    # With arguments, supply the Robot target explicitly, e.g. --dryrun tests.
    args = sys.argv[1:] or ['tests']
    return run_cli(['--outputdir', 'results', '--loglevel', 'INFO', *args], exit=False)


if __name__ == '__main__':
    sys.exit(main())
