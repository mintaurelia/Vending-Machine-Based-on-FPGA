# FPGA Vending Machine Controller

A Verilog HDL-based vending machine controller implemented with a finite state machine architecture. The system supports product selection, quantity control, payment processing, dispensing, transaction cancellation, and manual change return.

## Features

- Supports 16 products with configurable prices
- Supports purchasing up to two different products
- Supports quantities from 1 to 3 for each product
- Accepts coin denominations of 1, 5, 10, 20, and 50
- Calculates the total purchase price automatically
- Tracks the inserted amount during payment
- Detects payment completion automatically
- Simulates the product dispensing process
- Supports transaction cancellation
- Provides manual change return, one unit per button press
- Includes button synchronization and debouncing
- Provides LED-based system status indication
- Displays product and payment information on an eight-digit seven-segment display
- Includes a Verilog HDL simulation testbench

## System Architecture

The controller is divided into several functional modules:

| Module | Description |
| --- | --- |
| `vending_top` | Top-level module that integrates the complete system |
| `vending_fsm` | Finite state machine for transaction control |
| `price_rom` | Product price lookup module |
| `key_pulse` | Button synchronization, debouncing, and pulse generation |
| `display_controller` | Seven-segment display scanning and output control |
| Coin decoder | Decodes the selected coin denomination |
| Payment manager | Tracks inserted money and calculates change |
| Dispensing controller | Simulates the product dispensing process |

## Operating Flow

The main operating states are:

```text
IDLE
  |
  v
Product Selection
  |
  v
Quantity Selection
  |
  v
Second Product Selection (optional)
  |
  v
Total Price Confirmation
  |
  v
Payment
  |
  v
Dispensing
  |
  v
Change Return
  |
  v
IDLE
