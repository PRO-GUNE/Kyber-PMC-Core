# from utils.SpikingDataset import SpikingDataset
# root_folder = Path(os.getcwd())
# dataset_dir = root_folder / "data/har-up-spiking-dataset-240"
# dataset = SpikingDataset(root_dir=dataset_dir, time_duration=60, camera1_only=False, multiclass=False)
# train_dataset, dev_dataset, test_dataset = dataset.split_by_trials()

# events, target = test_dataset[0]

import time
import serial


starttime = time.monotonic()

numbers = 24

uart = serial.Serial(
    port="COM11",
    baudrate=115200,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    timeout=1,
)

byte_array = [
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    1,
    2,
    3,
]

uart.write(bytes(byte_array))
print(f"Sent {len(byte_array)} bytes to FPGA.")

while not uart.in_waiting:
    continue

# Read response
if uart.in_waiting:
    response = uart.read(len(byte_array) + 1)
    values = [
        int(response.hex()[i : i + 2], 16) for i in range(2, len(response.hex()), 2)
    ]
    print(f"Received from FPGA: {response.hex()[2:]}")
    print(values)

uart.close()
