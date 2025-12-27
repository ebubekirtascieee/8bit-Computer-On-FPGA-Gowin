"""
Instruction Set:

Opcode,    Mnemonic,   Arguments,     Operation
0000,        NOP,        None,           None
0001,        LDA,        Address,        A = RAM[Addr]
0010,        ADD,        Address,        A = A + RAM[Addr]
0011,        SUB,        Address,        A = A - RAM[Addr]
0100,        STA,        Address,        RAM[Addr] = A
0101,        LDI,        Immediate,      A = Immediate
0110,        JMP,        Address,        PC = Address
0111,        JC,         Address,        "If C=1, PC = Addr"
1000,        JZ,         Address,        "If Z=1, PC = Addr"
1001,        JNC,        Address,        "If C=0, PC = Addr"
1010,        AND,        Address,        A = A & RAM[Addr]
1011,        OR,         Address,        A = A | RAM[Addr]
1100,        XOR,        Address,        A = A ^ RAM[Addr]
1101,        SHL,        None,           A = A << 1
1110,        OUT,        None,           OUT = A
1111,        HLT,        None,           Clock Stop
"""

mnemonic_dic = {"NOP":"0000","LDA":"0001","ADD":"0010","SUB":"0011","STA":"0100","LDI":"0101","JMP":"0110","JC":"0111","JZ":"1000","JNC":"1001","AND":"1010","OR":"1011","XOR":"1100","SHL":"1101","OUT":"1110","HLT":"1111"}

with open("fibonacci.asm", "r") as code:
    lines = code.readlines()
    print("File Read Successfully!")

    machine_codes = []

    for line in lines:
        if line[0] != ";": #Comment Line
            first_space = line.find(" ")

            mnemonic = line[:first_space]
            argument = line[first_space+1:]

            binary_mnemonic = mnemonic_dic[mnemonic]

            if first_space != -1:
                binary_argument = str(bin(int(argument)))[2:]
                binary_argument = (4-len(binary_argument)) * "0" + binary_argument

            else:
                binary_argument = "0000"

            machine_codes.append(binary_mnemonic+binary_argument+"\n")

    for i in range(16-len(machine_codes)): #Fill the remaining ram address
        machine_codes.append("00000000\n")

    print(machine_codes)

with open("16byte_ram.mi","w") as ram:
    ram.writelines(machine_codes)
    print("RAM .mi file created successfully!")

