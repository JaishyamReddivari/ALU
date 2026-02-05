# ALU — Arithmetic Logic Unit (Verilog RTL + Testbench)

A simple **Arithmetic Logic Unit (ALU)** written in **Verilog HDL**, along with its testbench.  
This module supports basic arithmetic and logical operations — ideal for learning digital design and simulation.

---

## Repository Structure

### ALU
 - ALU.v # Verilog RTL for the ALU
 - ALU_tb.v # Testbench file for simulation
 -  README.md # This file


---

## Overview

An **Arithmetic Logic Unit (ALU)** is a core part of any processor. It performs arithmetic (ADD, SUB) and logical (AND, OR, XOR, etc.) operations on binary data.

This implementation takes:
- Two input operands (`A`, `B`)
- A select signal (`Op`) to choose the operation  
and produces:
- A result output (`Result`)
- Status flags such as `Zero`, `CarryOut`, and `Overflow` (if included)

> The actual supported operations depend on how `Op` is encoded in the Verilog ALU module.

---

## Features

- Verilog HDL implementation  
- Simple combinational ALU  
- Testbench for functional simulation  
- Easy to expand to more operations

---

## Ports (Approximate Example)

```verilog
module ALU (
  input  logic [3:0] A,
  input  logic [3:0] B,
  input  logic [2:0] Op,
  output logic [3:0] Result,
  output logic       Zero,
  output logic       CarryOut,
  output logic       Overflow
);
```

- A, B — input operands
- Op — ALU operation code
- Result — output of the operation
- Zero — asserted when the result is zero
- CarryOut — carry bit from arithmetic ops
- Overflow — indicates signed overflow
(Actual port names and widths may vary depending on your ALU RTL.)
