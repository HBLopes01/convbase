#!/bin/sh
nasm -f elf64 -o convbase.o convbase.asm && ld -o convbase.out convbase.o
