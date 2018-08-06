module mips.assembler.assm;

import std.stdio;
import std.conv: to, parse;
import std.typecons: Tuple;

import pegged.grammar: ParseTree;

import mips.def, mips.assembler.instdef;

Inst[] compileMips(ParseTree p)
{
    int idx = 0;
    string[] labels;
    Inst[] insts;
    foreach(line; p.children[0].children)
    {
        switch(line.name)
        {
        case "Mips.LabelLine":
            labels ~= line.matches[0];
            break;
        case "Mips.LabelInstLine":
            labels ~= line.matches[0];
            auto t = compileInst(line.children[1]);
            t[0].labels = labels;
            insts ~= t;
            labels = null;
            idx += 4;
            break;
        case "Mips.InstLine":
            auto t = compileInst(line.children[0]);
            t[0].labels = labels;
            insts ~= t;
            labels = null;
            idx += 4;
            break;
        default:
            throw new Exception(line.toString);
        }
    }
    if(!labels)
    {
        insts ~= new InstR(RegId.ze, RegId.ze, RegId.ze, 0, Funct.sll);
        insts[$-1].labels = labels;
    }
    return insts;
}

Inst[] compileInst(ParseTree p)
{
    switch(p.name)
    {
    case "Mips.Inst":
        return compileInst(p.children[0]);
    case "Mips.R1":
        return [new InstR(
            compileReg(p.children[2]),
            compileReg(p.children[3]),
            compileReg(p.children[1]),
            0,
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.R2":
        return [new InstR(
            compileReg(p.children[1]),
            compileReg(p.children[2]),
            RegId.ze,
            0,
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.R3":
        return [new InstR(
            RegId.ze,
            RegId.ze,
            compileReg(p.children[1]),
            0,
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.R4":
        return [new InstR(
            compileReg(p.children[2]),
            compileReg(p.children[1]),
            RegId.ze,
            0,
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.R5":
        return [new InstR(
            RegId.ze,
            compileReg(p.children[2]),
            compileReg(p.children[1]),
            compileImd(p.children[3]),
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.R6":
        return [new InstR(
            compileReg(p.children[1]),
            RegId.ze,
            RegId.ze,
            0,
            parse!Funct(p.children[0].matches[0])
        )];
    case "Mips.I1":
        return [new InstI(
            parse!Opecode(p.children[0].matches[0]),
            compileReg(p.children[2]),
            compileReg(p.children[1]),
            Address(compileImd(p.children[3]))
        )];
    case "Mips.I2":
        return [new InstI(
            parse!Opecode(p.children[0].matches[0]),
            compileReg(p.children[3]),
            compileReg(p.children[1]),
            Address(compileImd(p.children[2]))
        )];
    case "Mips.I3":
        return [new InstI(
            parse!Opecode(p.children[0].matches[0]),
            RegId.ze,
            compileReg(p.children[1]),
            Address(compileImd(p.children[2]))
        )];
    case "Mips.I4":
        return [new InstI(
            parse!Opecode(p.children[0].matches[0]),
            compileReg(p.children[1]),
            compileReg(p.children[2]),
            compileAdr(p.children[3], false)
        )];
    case "Mips.J":
        return [new InstJ(
            parse!Opecode(p.children[0].matches[0]),
            compileAdr(p.children[1], false)
        )];
    case "Mips.Mcr1":
        return [new InstI(
            Opecode.addi,
            compileReg(p.children[2]),
            compileReg(p.children[1]),
            Address(0)
        )];
    case "Mips.Mcr2":
        return [
            new InstI(
                Opecode.lui,
                RegId.ze,
                compileReg(p.children[1]),
                compileAdr(p.children[2], true),
                true
            ),
            new InstI(
                Opecode.ori,
                compileReg(p.children[1]),
                compileReg(p.children[1]),
                compileAdr(p.children[2], false)
        )];
    case "Mips.Mcr3":
        final switch(p.matches[0])
        {
        case "bgt":
            return [
                new InstR(
                    compileReg(p.children[2]),
                    compileReg(p.children[1]),
                    RegId.at,
                    0,
                    Funct.slt
                ),
                new InstI(
                    Opecode.bne,
                    RegId.at,
                    RegId.ze,
                    compileAdr(p.children[3], false)
            )];
        case "blt":
            return [
                new InstR(
                    compileReg(p.children[1]),
                    compileReg(p.children[2]),
                    RegId.at,
                    0,
                    Funct.slt
                ),
                new InstI(
                    Opecode.bne,
                    RegId.at,
                    RegId.ze,
                    compileAdr(p.children[3], false)
            )];
        case "bge":
            return [
                new InstR(
                    compileReg(p.children[1]),
                    compileReg(p.children[2]),
                    RegId.at,
                    0,
                    Funct.slt
                ),
                new InstI(
                    Opecode.beq,
                    RegId.at,
                    RegId.ze,
                    compileAdr(p.children[3], false)
            )];
        case "ble":
            return [
                new InstR(
                    compileReg(p.children[2]),
                    compileReg(p.children[1]),
                    RegId.at,
                    0,
                    Funct.slt
                ),
                new InstI(
                    Opecode.beq,
                    RegId.at,
                    RegId.ze,
                    compileAdr(p.children[3], false)
            )];
        }
    case "Mips.Mcr4":
        return [
            new InstR(
                compileReg(p.children[1]),
                compileReg(p.children[2]),
                RegId.ze,
                0,
                Funct.mult
            ),
            new InstR(
                RegId.ze,
                RegId.ze,
                compileReg(p.children[1]),
                0,
                Funct.mflo
        )];
    case "Mips.Mcr5":
        final switch(p.matches[0])
        {
        case "nop":
            return [new InstR(
                RegId.ze,
                RegId.ze,
                RegId.ze,
                0,
                Funct.sll
            )];
        case "syscall":
            return [new InstR(
                RegId.ze,
                RegId.ze,
                RegId.ze,
                0,
                Funct.syscall
            )];
        }
    default:
        break;
    }
    throw new Exception(p.toString);
}


Address compileAdr(in ParseTree p, in bool upper)
{
    switch(p.name)
    {
    case "Mips.Adr": return compileAdr(p.children[0], upper);
    case "Mips.Imd": return Address(compileImd(p));
    case "Mips.Identifier": return Address(Tuple!(string, bool)(p.matches[0], upper));
    default:
        throw new Exception(p.toString);
    }
}

int compileImd(in ParseTree p)
{
    switch(p.name)
    {
    case "Mips.Imd": return compileImd(p.children[0]);
    case "Mips.Digit": return p.matches[0].to!int;
    case "Mips.Hex": return p.matches[0].to!int(16);
    default:
        throw new Exception(p.toString);
    }
}

RegId compileReg(in ParseTree p)
{
    if(p.name == "Mips.Reg")
        return compileReg(p.children[0]);
    else
        return cast(RegId)p.name[8..$].to!int;
}





