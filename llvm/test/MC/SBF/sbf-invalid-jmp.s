# RUN: not llvm-mc %s -triple=sbf-solana-solana -filetype=obj \
# RUN:     -o /dev/null 2>&1 | FileCheck %s


# The original BPF does not support 16-bit relocations, so we currently
# don't either. But we will now emit an error message for SBF instead of
# asserting as the BPF back-end does.
# CHECK: <unknown>:0: error: 2-byte relocations not supported
ja undefined_label

