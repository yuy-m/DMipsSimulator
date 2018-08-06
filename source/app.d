import std.stdio;
import mips.assembler, mips.computer.com;
import std.path;
import std.getopt;

void main(string[] args)
{
    if(args.length == 1)
    {
        stderr.writeln("illegal argument");
        return;
    }
    switch(args[1])
    {
    case "asm":
        string oname = null;
        bool verbose = false;
        args.getopt("o", &oname, "v", &verbose);
        runAssembler(args[2], oname, verbose);
        break;
    case "run":
        auto c = new Processor();
        c.loadProgramFromFile(args[2]);
        c.run;
        break;
    case "both":
        auto c = new Processor();
        c.loadProgram(assemble(args[2], false), false);
        c.run;
        break;
    default:
        stderr.writeln("illegal argument");
    }
}

