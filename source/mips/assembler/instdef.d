module mips.assembler.instdef;

import std.variant: Algebraic;
import std.typecons: Tuple;

import mips.def;
import std.format: format;

alias Address = Algebraic!(int, Tuple!(string, bool));

abstract class Inst
{
    string[] labels;
    Opecode ope;
    abstract uword_t toCode();
}

class InstR: Inst
{
    RegId rs;
    RegId rt;
    RegId rd;
    int shift;
    Funct funct;
    this(RegId rs, RegId rt,RegId rd, int shift, Funct funct)
    {
        this.ope = Opecode.rinst;
        this.rs = rs;
        this.rt = rt;
        this.rd = rd;
        this.shift = shift;
        this.funct = funct;
    }
    override uword_t toCode()
    {
        return ((rs & 0x1F) << 21)
            | ((rt & 0x1F) << 16)
            | ((rd & 0x1F) << 11)
            | ((shift & 0x1F) << 6)
            | (funct & 0x3F);
    }
    override string toString()
    {
        return format!"fn:%-7s, rs:%02s, rt:%02s, rd:%02s, sh:%2s    : %-(%s, %)"(funct, rs, rt, rd, shift, labels);
    }
}


class InstI: Inst
{
    RegId rs;
    RegId rt;
    Address imd;
    bool use_upper_imd;
    this(Opecode ope, RegId rs, RegId rt, Address imd, bool use_upper_imd = false)
    {
        this.ope = ope;
        this.rs = rs;
        this.rt = rt;
        this.imd = imd;
        this.use_upper_imd = use_upper_imd;
    }
    override uword_t toCode()
    {
        return ((ope & 0x3F) << 26)
            | ((rs & 0x1F) << 21)
            | ((rt & 0x1F) << 16)
            | ((use_upper_imd
                ? (imd.get!int >>> 16)
                : imd.get!int) & 0xFFFF);
    }
    override string toString()
    {
        return format!"op:%-7s, rs:%02s, rt:%02s, imd:%10s  : %-(%s, %)"(ope, rs, rt, imd.toString, labels);
    }
}

class InstJ: Inst
{
    Address adr;
    this(Opecode ope, Address adr)
    {
        this.ope = ope;
        this.adr = adr;
    }
    override uword_t toCode()
    {
        return ((ope & 0x3F) << 26)
            | ((adr.get!int >>> 2) & 0x3FFFFFF);
    }
    override string toString()
    {
        return format!"op:%-7s, adr:%10s                : %-(%s, %)"(ope, adr.toString, labels);
    }
}

