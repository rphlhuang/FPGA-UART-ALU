"""
Packet format:
0	    Opcode	        Specifies the operation
1	    Reserved	    Reserved for future use
2	    Length (LSB)	Least significant byte of the data length
3	    Length (MSB)	Most significant byte of the data length
4-(Length-1)	Data	Data with specified length
"""

import serial, threading, time

SERIAL_PORT = "/dev/tty.usbserial-ibp57T8M1"
BAUD_RATE = 115200

# open serial connection
ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

def read_from_uart():
    while True:
        if ser.in_waiting > 0:  # ser.in_waitng: the number of bytes in the input buffer
            data = ser.read(ser.in_waiting)
            utf8_data = data.decode('UTF-8', errors='ignore')
            hex_data = data.hex()
            print(f'Received: 0x{hex_data}, "{utf8_data}"')

# start a thread to read data asynchronously
read_thread = threading.Thread(target=read_from_uart, daemon=True)
read_thread.start()

# send single byte to UART
def send_byte(data):
    byte = bytes([data])
    ser.write(byte)
    print(f'Sent: {byte.hex()}')

# send packet to UART
def send_packet(opcode, data):
    length = len(data) + 4  # 4 byte header
    length_lsb = length & 0xFF
    length_msb = (length >> 8) & 0xFF
    packet = bytearray([opcode, 0x00, length_lsb, length_msb])
    packet.extend(data)

    ser.write(packet)
    print(f'Sent: {packet.hex()}')

send_byte(0x55)
time.sleep(0.01)
send_packet(0xEC, b"Hi")

# keep the script running
try:
    while True:
        pass
except KeyboardInterrupt:
    print("Exiting...")
    ser.close()
