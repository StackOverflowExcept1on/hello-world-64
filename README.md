# hello-world-64

[![Build Status](https://github.com/StackOverflowExcept1on/hello-world-64/actions/workflows/build.yml/badge.svg)](https://github.com/StackOverflowExcept1on/hello-world-64/actions/workflows/build.yml)

The real programmers can write hello world in 64 bytes of machine code!

![image](https://i.imgur.com/DqUNBSV.png)

This repository contains code in assembly language targeting Windows x86_64.

Here is a list of things that are used to achieve this size:

- undocumented `PEB` structure - https://en.wikipedia.org/wiki/Process_Environment_Block
- syscall ABI on Windows
- shadow space in stacks
- a lot of hacks to reduce code size
    - push & pop compiles to 3 bytes of machine code (val < 128)
      ```asm
      ; reg = val
      push val ; 2 bytes
      pop reg ; 1 byte
      ```
    - hack that allows to push string address to the stack and pop it back
      ```asm
      ; reg = address of data, i.e. reg points to "my data goes here"
      call data_label
      data: db 'my data goes here'
      data_label: pop reg
      ```
    - xor of 32-bit registers allows us to zero out a 64-bit register in 2 bytes of code
      ```asm
      xor edx, edx ; 31 d2
      xor rdx, rdx ; 48 31 d2
      ; but it's same
      ```
    - if you want to set `rdx` to `0` you can use `cdq` to do it in 1 byte (bit 63 of rax should be 0)
      ```asm
      push 0x60 ; 6a 60
      pop rax ; 58 (rax = 0x60, bit 63 of rax = 0)
      cdq ; rdx = 0
      ```
- see [main.asm](main.asm) for better explanation

### Building

You need to install [NASM](https://nasm.us) and unpack it into this directory or add to env variable PATH
