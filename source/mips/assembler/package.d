module mips.assembler;

import std.stdio;
import std.traits: isSomeString;

void runAssembler(S1, S2)(in S1 fname, in S2 oname, in bool verbose)
    if(isSomeString!S1 && isSomeString!S2)
{
    import std.path: setExtension;
    import std.file: readText;

    assemble(readText(fname), verbose)
        .writeTo(oname is null? fname.setExtension("com"): oname);
}

auto assemble(S)(in S code, in bool verbose)
    if(isSomeString!S)
{
    import mips.assembler.assm, mips.assembler.gen, mips.assembler.prs;

    auto parseTree = Mips(code);
    auto insts = compileMips(parseTree);
    if(verbose)
    {
        foreach(idx, inst; insts)
        {
            writefln!"%08x : %s"(idx, inst);
        }
    }

    auto labels = insts.extractLabels;
    if(verbose)
    {
        foreach(lbl, adr; labels)
        {
            writefln!"%10s : %08x"(lbl, adr);
        }
    }

    insts.solveLabels(labels);

    import std.algorithm: map;
    return insts.map!(a => a.toCode);
}

import std.range: isInputRange, ElementType;

void writeTo(R, S)(R code, in S fname)
    if(isInputRange!R && is(ElementType!R == uint) && isSomeString!S)
{
    import std.file: write;
    import std.path: defaultExtension;
    import std.array: array;
    fname.defaultExtension("com")
        .write(code.array);
}
