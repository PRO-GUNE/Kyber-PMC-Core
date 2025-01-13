# Generate init file for 4 bank RAM
# Equations:
#   BA = A >> 2
#   BI = (A[1:0] + 2(A[6]+A[5]+A[4]+A[3]+A[2] mod 2)) mod 4

N = 128  # Number of addresses
N_4 = int(N / 4)
DEBUG = True


# Function to return a value for a given address
# A 24-bit number (6 HEX digits)
def f(i: int) -> int:
    a_0 = 2 * i
    a_1 = 2 * (i + 1)
    return a_0 | a_1 << 12


# Function to create conflict free address mapping for original address
def map_addr(addr: int) -> tuple:
    BA = int(addr / 4)
    slide = addr // 4
    BI = ((addr % 32) + 2 * ((slide | slide))) % 4

    return (BI, BA)


# Debug printing function
def debug(*values):
    if DEBUG:
        print(*values)


# Address and Value pairs
addr_value_pairs = [(i, f(i)) for i in range(N)]

# Memory bank representation
mem_banks = {j: [0 for _ in range(N_4)] for j in range(4)}
debug(mem_banks)

for addr, val in addr_value_pairs:
    BA, BI = map_addr(addr)
    debug(BA, BI)
    mem_banks.get(BA)[BI] = val

debug(mem_banks)

# Convert to files
for key, values in mem_banks.items():
    filename = f"./imports/mem_bank_{key}.coe"
    with open(filename, "w") as file:
        # Write the header lines
        file.write("memory_initialization_radix=16;\n")
        file.write("memory_initialization_vector=\n")
        # Write values as comma-separated, one per line
        for i, value in enumerate(values):
            # Convert value to hexadecimal
            hex_value = f"{value:X}"
            # Append a comma except for the last value
            if i < len(values) - 1:
                file.write(f"{hex_value},\n")
            else:
                file.write(f"{hex_value};\n")  # Semicolon at the end of the last value
