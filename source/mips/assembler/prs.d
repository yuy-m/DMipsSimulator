module mips.assembler.prs;

import pegged.grammar;

/+asModule(
    "mips.assembler.grammar",
    "source/mips/assembler/grammar",
    grm);+/

mixin(grammar(grm));

private enum grm = `
Mips:
    Lines < (Endl / InstLine / LabelInstLine / LabelLine)+ eoi

    InstLine < Inst Endl
    LabelInstLine < Label Inst Endl
    LabelLine < Label Endl
    Label < ~Identifier :':'
    Endl <: ("#" (!(eol / eoi) .)*)? (eol / eoi)

    Identifier < :!(Mnem ![a-zA-Z_0-9] .) ~([a-zA-Z_] [a-zA-Z_0-9]*)

    Spacing <- space*
    cma <: ','

    Inst <- R1 / R2 / R3 / R4 / R5 / R6 / I1 / I2 / I3 / I4 / J / Mcr1 / Mcr2 / Mcr3 / Mcr4 / Mcr5
    Mnem <- R1M | R2M | R3M | R4M | R5M | R6M | I1M | I2M | I3M | I4M | JM | Mcr1M | Mcr2M | Mcr3M | Mcr4M | Mcr5M

    R1 <- ~R1M Reg cma Reg cma Reg
    R1M < "addu" / "add" / "subu" / "sub" / "and" / "or" / "xor" / "nor" / "slt"
    R2 < ~R2M Reg cma Reg
    R2M < "mult" / "divu" / "div"
    R3 < ~R3M Reg
    R3M < "mfhi" / "mflo"
    R4 < ~R4M Reg cma Reg
    R4M < "mfcZ" / "mtcZ"
    R5 < ~R5M Reg cma Reg cma Digit
    R5M < "sll" / "srl" / "sra"
    R6 < ~R6M Reg
    R6M < "jr"

    I1 < ~I1M Reg cma Reg cma Imd
    I1M < "addiu" / "addi" / "andi" / "ori" / "slti"
    I2 < ~I2M Reg cma Imd :"(" Reg :")"
    I2M < "lw" / "lhu" / "lh" / "lbu" / "lb" / "sw" / "sh" / "sb"
    I3 < ~I3M Reg cma Imd
    I3M < "lui"
    I4 < ~I4M Reg cma Reg cma Adr
    I4M < "beq" / "bne"

    J  < ~JM Adr
    JM < "jal" / "j"

    Mcr1 < ~Mcr1M Reg cma Reg
    Mcr1M < "move"
    Mcr2 < ~Mcr2M Reg cma Adr
    Mcr2M < "la" / "li"
    Mcr3 < ~Mcr3M Reg cma Reg cma Adr
    Mcr3M < "bgt" / "blt" / "bge" / "ble"
    Mcr4 < ~Mcr4M Reg cma Reg cma Reg
    Mcr4M < "mul"
    Mcr5 < ~Mcr5M
    Mcr5M < "nop" / "syscall"

    Imd < Hex / Digit
    Digit <~ [-+]? digits
    Hex <~ [-+]? :"0x" [0-9a-fA-Z]+

    Adr < Imd / Identifier

    Reg <- "$" (Reg10 / Reg11 / Reg12 / Reg13 / Reg14 / Reg15 / Reg16 / Reg17 / Reg18 / Reg19
                / Reg20 / Reg21 / Reg22 / Reg23 / Reg24 / Reg25 / Reg26 / Reg27 / Reg28 / Reg29
                / Reg30 / Reg31
                / Reg00 / Reg01 / Reg02 / Reg03 / Reg04 / Reg05 / Reg06 / Reg07 / Reg08 / Reg09)
    Reg00 <  "0" / "ze"
    Reg01 <  "1" / "at"
    Reg02 <  "2" / "v0"
    Reg03 <  "3" / "v1"
    Reg04 <  "4" / "a0"
    Reg05 <  "5" / "a1"
    Reg06 <  "6" / "a2"
    Reg07 <  "7" / "a3"
    Reg08 <  "8" / "t0"
    Reg09 <  "9" / "t1"
    Reg10 < "10" / "t2"
    Reg11 < "11" / "t3"
    Reg12 < "12" / "t4"
    Reg13 < "13" / "t5"
    Reg14 < "14" / "t6"
    Reg15 < "15" / "t7"
    Reg16 < "16" / "s0"
    Reg17 < "17" / "s1"
    Reg18 < "18" / "s2"
    Reg19 < "19" / "s3"
    Reg20 < "20" / "s4"
    Reg21 < "21" / "s5"
    Reg22 < "22" / "s6"
    Reg23 < "23" / "s7"
    Reg24 < "24" / "t8"
    Reg25 < "25" / "t9"
    Reg26 < "26" / "k0"
    Reg27 < "27" / "k1"
    Reg28 < "28" / "gp"
    Reg29 < "29" / "sp"
    Reg30 < "30" / "fp"
    Reg31 < "31" / "ra"
`;
