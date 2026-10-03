FPGA Vending Machine Controller
This project implements a digital vending machine controller using Verilog HDL and a finite state machine architecture. It is designed for FPGA hardware and supports the complete vending workflow, from product selection to payment, dispensing, and change return.

Features
Supports 16 products with configurable prices
Allows customers to purchase up to two different products
Supports quantities from 1 to 3 for each product
Accepts multiple coin denominations: 1, 5, 10, 20, and 50
Calculates the total purchase price automatically
Tracks the inserted amount during payment
Automatically detects payment completion
Simulates the dispensing process
Supports transaction cancellation
Provides manual change return, one unit per button press
Includes button synchronization, debouncing, and pulse generation
Displays system status using LEDs
Displays product information, prices, inserted money, and change using an eight-digit seven-segment display
Includes a Verilog simulation testbench for functional verification
System Architecture
The controller is organized into several functional modules:

vending_top: Top-level system integration module
vending_fsm: Finite state machine for transaction control
price_rom: Product price lookup module
key_pulse: Button synchronization and debouncing module
display_controller: Seven-segment display scanning and output module
Payment and coin decoding logic
Product selection and quantity management logic
Change management and dispensing control logic
The main operating states include idle, product selection, quantity selection, total price confirmation, payment, dispensing, and change return.

Verification
The design can be verified through simulation using a dedicated testbench. The test scenarios cover reset behavior, button debouncing, product and quantity selection, invalid quantity handling, coin decoding, payment accumulation, automatic dispensing, transaction cancellation, change calculation, and return to the idle state.

Target Hardware
The design is suitable for FPGA development boards equipped with:

Push buttons
Slide switches
LEDs
An eight-digit seven-segment display
The included constraint file can be adapted to the target board and pin assignments.
