# FPGA Vending Machine Controller 
# 东南大学暑期学校FPGA项目

This project was developed as a digital systems course design project during the second-year summer school at the School of Information, Southeast University.
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
```

The system uses button pulses to control state transitions. Invalid quantities and invalid coin combinations are rejected by the control logic.

## Product Selection

The system provides 16 product entries. Each product has a corresponding price stored in the price lookup module.

A customer can:

1. Select the first product.
2. Select a quantity from 1 to 3.
3. Continue with an optional second product.
4. Confirm the total price.
5. Insert coins until the payment requirement is satisfied.

## Payment and Change

The system accepts the following coin values:

| Switch Input | Coin Value |
| --- | ---: |
| `10000` | 50 |
| `01000` | 20 |
| `00100` | 10 |
| `00010` | 5 |
| `00001` | 1 |

Only one coin-selection switch may be active at a time. No coin is accepted when all switches are off or multiple switches are active.

When the inserted amount reaches or exceeds the total price, the system enters the dispensing state. Any excess amount is stored as change. Change is returned manually, one unit per button press.

## Display and Indicators

The eight-digit seven-segment display is used to show:

| Display Position | Information |
| --- | --- |
| 1 | First product code |
| 2 | First product quantity |
| 3 | Second product code |
| 4 | Second product quantity |
| 5-6 | Total price |
| 7-8 | Inserted amount or remaining change |

LED indicators show the current system state. An additional error indicator is used when an invalid quantity is selected.

## Verification

The design includes a Verilog HDL testbench for functional simulation.

The verification scenarios include:

- System reset and return to the idle state
- Button debouncing and pulse generation
- Product selection
- Quantity selection
- Invalid quantity detection
- Single-product purchases
- Two-product purchases
- Coin denomination decoding
- Payment accumulation
- Payment completion detection
- Dispensing state transition
- Transaction cancellation
- Change calculation
- Manual change return
- Return to the idle state

## Target Hardware

The design is intended for FPGA development boards with:

- Push buttons
- Slide switches
- LEDs
- An eight-digit seven-segment display

The constraint file can be adapted to match the pin assignments of the target FPGA development board.

## Source Files

Typical project files include:

```text
vending_top.v
vending_fsm.v
price_rom.v
key_pulse.v
display_controller.v
vending_top_tb.v
Nexys4DDR_Master.xdc
```

## HDL and Tools

- Verilog HDL
- FPGA-based digital system design
- Finite state machine control
- Seven-segment display multiplexing
- Functional simulation
