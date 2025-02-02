"""
Packet format:
0	    Opcode	        Specifies the operation
1	    Reserved	    Reserved for future use
2	    Length (LSB)	Least significant byte of the data length
3	    Length (MSB)	Most significant byte of the data length
4-(Length-1)	Data	Data with specified length

Opcodes:
--------------------------
|  Operation  |  Opcode  |
|  echo       |  0xec    |
|  add32      |  0x10    |
|  mul32      |  0x11    |
|  div32      |  0x12    |
--------------------------
"""

import serial, threading, time, struct

SERIAL_PORT = "/dev/tty.usbserial-ibp57T8M1"
BAUD_RATE = 115200

# open serial connection
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

def read_from_uart():
    while True:
        if ser.in_waiting > 0:  # ser.in_waitng: the number of bytes in the input buffer
            data = ser.read(ser.in_waiting)
            # utf8_data = data.decode('UTF-8', errors='ignore')
            hex_data = data.hex()
            decimal_data = int.from_bytes(data, byteorder="big")
            print(f'Received: 0x{hex_data}, 0d{decimal_data}')


# start a thread to read data asynchronously
read_thread = threading.Thread(target=read_from_uart, daemon=True)
read_thread.start()

# send single byte to UART
def send_byte(data):
    byte = bytes([data])
    ser.write(byte)
    print(f'Sent: {byte.hex()}')

# send packet to UART
def send_packet(opcode, data, num_ops):
    # length = len(data) + 4  # 4 byte header
    # length = len(data)
    length = num_ops
    length_lsb = length & 0xFF
    length_msb = (length >> 8) & 0xFF
    packet = bytearray([opcode, 0x00, length_lsb, length_msb])
    packet.extend(data)

    ser.write(packet)
    print(f'Sent: {packet.hex()}')
    time.sleep(0.02)

def add32(operands):
    payload = bytearray()
    num_ops = 0
    for op in operands:
        payload.extend(op.to_bytes(4, 'big'))  # each operand is 4 bytes
        num_ops += 1
    print(f"\n---\nAdding {num_ops} integers: {operands}")
    send_packet(0x10, payload, num_ops)

def mul32(operands):
    payload = bytearray()
    num_ops = 0
    for op in operands:
        payload.extend(op.to_bytes(4, 'big'))  # each operand is 4 bytes
        num_ops += 1
    print(f"Multiplying {num_ops} integers: {operands}")
    send_packet(0x11, payload, num_ops)

def div32(numerator, denominator):
    send_packet(0x12, bytearray([numerator, denominator]))

# send_byte(0x55)
time.sleep(0.01)
# send_packet(0xEC, b"Hi")

add32([0x01, 0x02])
time.sleep(0.01)
add32([0x03, 0x04])
time.sleep(0.01)
add32([200, 93])
time.sleep(0.01)
add32([0x01, 0x02, 0x03, 0x4, 0x5])



# mul32([0x10, 0x55])
# div32(0x0A, 0x02)


# keep the script running
try:
    while True:
        pass
except KeyboardInterrupt:
    print("Exiting...")
    ser.close()
