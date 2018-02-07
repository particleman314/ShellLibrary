#!/usr/bin/env bash

diag 'This is a simple test of output'
diag This is a multiline test of output
diag --msgformat "\\b\\n" 'Another test of output'

__reset_plan
