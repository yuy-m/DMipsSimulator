module mips.computer.com;

import std.stdio;
import std.traits;
import std.range;
import std.typecons, std.variant;
import std.experimental.checkedint;

import mips.computer.mem, mips.def;

class Processor
{
    private word_t pc;
    private Regs regs;
    private Memory mem;
    private word_t hi;
    private word_t lo;
    private uword_t brk;
    private bool[uword_t] br_points;

    static immutable program_segment = 0x80000000;
    static immutable data_segment = 0x90000000;

    void loadProgram(Range)(Range insts, in int offset = program_segment)
        if(isInputRange!Range && is(ElementType!Range == ubyte))
    {
        clear();
        foreach(idx, inst; insts)
        {
            mem.setByte(inst, offset + idx);
        }
    }
    void loadProgram(Range)(Range insts, in int offset = program_segment)
        if(isInputRange!Range && is(ElementType!Range == uword_t))
    {
        clear();
        uword_t idx = offset;
        foreach(inst; insts)
        {
            mem[idx] = inst;
            idx += 4;
        }
    }
    void loadProgramFromFile(S)(in S file_name, in int offset = program_segment)
        if(isSomeString!S)
    {
        auto f = File(file_name, "r");
        loadProgram(f.rawRead(new uword_t[](1000)), offset);
    }

    void clear()
    {
        pc = program_segment;
        regs.clear;
        mem.clear;
        hi = 0;
        lo = 0;
        brk = 0x40000000;
    }

    void run()
    {
        int cnt = 0;
        while(pc != 0 && cnt != -2)
        {
            if(cnt == 0 || pc in br_points)
            {
                writeRegsln;
                while(cnt == 0 || pc in br_points)
                    command(cnt);
            }

            if(cnt > 0)
            {
                step;
                --cnt;
            }
            else if(cnt == -1)
            {
                step;
            }
        }
        // writeRegsln;
    }

    void command(ref int cnt)
    {
        import std.string;
        write(" > ");
        stdout.flush;
        immutable cmds = readln.strip.split;
        if(cmds.length == 0)
        {
            cnt = 1;
            return;
        }
        switch(cmds[0])
        {
        case "s", "step":
            if(cmds.length == 1)
            {
                cnt = 1;
            }
            else if(cmds.length == 2)
            {
                cnt = cmds[1].parseNumber;
            }
            break;
        case "r", "run":
            cnt = -1;
            break;
        case "b", "break":
            if(cmds.length == 2)
            {
                br_points[cmds[1].parseNumber] = true;
            }
            break;
        case "rm", "remove":
            if(cmds.length == 2)
            {
                br_points.remove(cmds[1].parseNumber);
            }
            break;
        case "q", "quit":
            cnt = -2;
            break;
        case "du", "dump":
            if(cmds.length == 2)
            {
                dump(cmds[1].parseNumber);
            }
            break;
        case "c", "code":
            immutable adr = (cmds.length >= 2)? cmds[1].parseNumber: pc;
            immutable num = (cmds.length == 3)? cmds[2].parseNumber: 10;
            foreach(i, inst; mem.sliceCountWord(adr, num))
            {
                writefln!"%08x:%08x : %s"(adr + i, inst, convInstToString(inst));
            }
            break;
        case "st", "stack":
            dump(regs[RegId.sp]);
            break;
        default:
            break;
        }
        stdout.flush;
    }

    void step()
    {
        immutable inst = mem[pc];
        final switch(inst.ope)
        {
        case Opecode.rinst:
            final switch(inst.funct)
            {
            case Funct.add:
            case Funct.addu:
                regs[inst.rd] = regs[inst.rs] + regs[inst.rt];
                break;
            case Funct.sub:
            case Funct.subu:
                regs[inst.rd] = regs[inst.rs] - regs[inst.rt];
                break;
            case Funct.mult:
                immutable res = (cast(long)regs[inst.rs]) * regs[inst.rt];
                hi = (res >>> 16) & 0xFFFF;
                lo = res & 0xFFFF;
                break;
            case Funct.div:
                lo = regs[inst.rs] / regs[inst.rt];
                hi = regs[inst.rs] % regs[inst.rt];
                break;
            case Funct.divu:
                immutable rs = cast(uword_t)regs[inst.rs];
                immutable rt = cast(uword_t)regs[inst.rt];
                lo = rs / rt;
                hi = rs % rt;
                break;
            case Funct.mfhi:
                regs[inst.rd] = hi;
                break;
            case Funct.mflo:
                regs[inst.rd] = lo;
                break;
            // Funct.mfcZ:
            // Funct.mtcZ:
            case Funct.and:
                regs[inst.rd] = regs[inst.rs] & regs[inst.rt];
                break;
            case Funct.or:
                regs[inst.rd] = regs[inst.rs] | regs[inst.rt];
                break;
            case Funct.xor:
                regs[inst.rd] = regs[inst.rs] ^ regs[inst.rt];
                break;
            case Funct.nor:
                regs[inst.rd] = ~(regs[inst.rs] | regs[inst.rt]);
                break;
            case Funct.slt:
                regs[inst.rd] = regs[inst.rs] < regs[inst.rt]? 1: 0;
                break;
            case Funct.sll:
                regs[inst.rd] = regs[inst.rt] >>> inst.shift;
                break;
            case Funct.srl:
                regs[inst.rd] = regs[inst.rt] << inst.shift;
                break;
            case Funct.sra:
                regs[inst.rd] = regs[inst.rt] >> inst.shift;
                break;
            case Funct.jr:
                pc = regs[inst.rs];
                return;
            case Funct.syscall:
                switch(regs[RegId.v0])
                {
                case SysCallCode.PrintInteger:
                    writeln(regs[RegId.a0]);
                    break;
                case SysCallCode.PrintString:
                    for(uword_t i = regs[RegId.a0]; mem[i] != 0; i += 4)
                    {
                        write(mem[i]);
                    }
                    writeln;
                    break;
                case SysCallCode.ReadInteger:
                    import std.string: strip;
                    regs[RegId.v0] = readln.strip.parseNumber!word_t;
                    break;
                case SysCallCode.ReadString:
                    immutable s = readln;
                    foreach(i, c; s)
                    {
                        mem[regs[RegId.a0] + 4 * i] = c;
                    }
                    regs[RegId.a1] = s.length + 1;
                    break;
                case SysCallCode.MemoryAllocation:
                    regs[RegId.v0] = brk;
                    brk += regs[RegId.a0];
                    break;
                case SysCallCode.Exit:
                    pc = 0;
                    return;
                case SysCallCode.PrintChar:
                    writeln(cast(char)regs[RegId.a0]);
                    break;
                case SysCallCode.ReadChar:
                    regs[RegId.v0] = readln[0];
                    break;
                default:
                    break;
                }
                break;
            }
            break;
        case Opecode.addi:
        case Opecode.addiu:
            regs[inst.rt] = regs[inst.rs] + inst.imdExt;
            break;
        case Opecode.lw:
            regs[inst.rt] = mem[inst.rs + inst.imdExt];
            break;
        case Opecode.lh:
            regs[inst.rt] = mem.getHalf(inst.rs + inst.imdExt).extendSignHalf;
            break;
        case Opecode.lhu:
            regs[inst.rt] = mem.getHalf(inst.rs + inst.imdExt);
            break;
        case Opecode.lb:
            regs[inst.rt] = mem.getByte(inst.rs + inst.imdExt).extendSignByte;
            break;
        case Opecode.lbu:
            regs[inst.rt] = mem.getByte(inst.rs + inst.imdExt);
            break;
        case Opecode.sw:
            mem[inst.rs + inst.imdExt] = regs[inst.rt];
            break;
        case Opecode.sh:
            mem.setHalf(regs[inst.rt], inst.rs + inst.imdExt);
            break;
        case Opecode.sb:
            mem.setByte(regs[inst.rt], inst.rs + inst.imdExt);
            break;
        case Opecode.lui:
            regs[inst.rt] = inst.imd << 16;
            break;
        case Opecode.andi:
            regs[inst.rt] = regs[inst.rs] & inst.imd;
            break;
        case Opecode.ori:
            regs[inst.rt] = regs[inst.rs] | inst.imd;
            break;
        case Opecode.slti:
            regs[inst.rt] = regs[inst.rs] < inst.imdExt? 1: 0;
            break;
        case Opecode.beq:
            if(regs[inst.rs] == regs[inst.rt])
                pc += inst.imdExt * 4;
            break;
        case Opecode.bne:
            if(regs[inst.rs] != regs[inst.rt])
                pc += inst.imdExt * 4;
            break;
        case Opecode.jal:
            regs[RegId.ra] = pc + 8;
            goto case;
        case Opecode.j:
            pc = ((pc+4) & 0xF0000000) | (inst.adr << 2);
            return;
        }
        pc += 4;
    }

    void dump(in uint adr) const
    {
        void printmem(in uint _adr) const
        {
            writefln!"%08x: %(%08x %)"(_adr, mem.sliceCountWord(adr, 8));
        }
        printmem(adr);
        if(uint.max - 8 >= adr)
            printmem(adr + 8);
        if(uint.max - 16 >= adr)
            printmem(adr + 16);
        if(uint.max - 24 >= adr)
            printmem(adr + 24);
    }

    void writeRegsln() const
    {
        immutable inst = mem[pc];
        with(RegId)
        {
            writefln!"pc(%08x) %08x: %s"(pc, inst, convInstToString(inst));
            writefln!"v0(%08x) v1(%08x) a0(%08x) a1(%08x) a2(%08x) a3(%08x)"(regs[v0], regs[v1], regs[a0], regs[a1], regs[a2], regs[a3]);
            writefln!"k0(%08x) k1(%08x) gp(%08x) sp(%08x) fp(%08x) ra(%08x)"(regs[k0], regs[k1], regs[gp], regs[sp], regs[fp], regs[ra]);
            writefln!"at(%08x) hi(%08x) lo(%08x)"(regs[at], hi, lo);
            writefln!"t0(%08x) t1(%08x) t2(%08x) t3(%08x) t4(%08x)"(regs[t0], regs[t1], regs[t2], regs[t3], regs[t4]);
            writefln!"t5(%08x) t6(%08x) t7(%08x) t8(%08x) t9(%08x)"(regs[t5], regs[t6], regs[t7], regs[t8], regs[t9]);
            writefln!"s0(%08x) s1(%08x) s2(%08x) s3(%08x)"(regs[s0], regs[s1], regs[s2], regs[s3]);
            writefln!"s4(%08x) s5(%08x) s6(%08x) s7(%08x)"(regs[s4], regs[s5], regs[s6], regs[s7]);
        }
        stdout.flush;
    }
    string convInstToString(in word_t inst) const
    {
        import std.format: format;
        final switch(inst.ope)
        {
        case Opecode.rinst:
            final switch(inst.funct)
            {
            case Funct.add, Funct.addu, Funct.sub, Funct.subu:
            case Funct.mult, Funct.div, Funct.divu:
            case Funct.and, Funct.or, Funct.xor, Funct.nor:
            case Funct.slt:
                return format!"%-5s $%s, $%s, $%s"(inst.funct, inst.rd, inst.rs, inst.rt);
            case Funct.mfhi, Funct.mflo:
                return format!"%-5s $%s"(inst.funct, inst.rd);
            // case Funct.mfcZ, Funct.mtcZ:
            case Funct.sll, Funct.srl, Funct.sra:
                return format!"%-5s $%s, $%s, %2s"(inst.funct, inst.rd, inst.rt, inst.shift);
            case Funct.jr:
                return format!"%-5s $%s"(inst.funct, inst.rs);
            case Funct.syscall:
                return format!"%-5s"(inst.funct);
            }
            assert(0);
        case Opecode.addi, Opecode.addiu:
        case Opecode.slti:
            return format!"%-5s $%s, $%s, %5s"(inst.ope, inst.rt, inst.rs, inst.imdExt);
        case Opecode.andi, Opecode.ori:
            return format!"%-5s $%s, $%s, 0x%04x"(inst.ope, inst.rt, inst.rs, inst.imd);
        case Opecode.lw, Opecode.lh, Opecode.lhu, Opecode.lb, Opecode.lbu:
        case Opecode.sw, Opecode.sh, Opecode.sb:
            return format!"%-5s $%s, %04x($%s)"(inst.ope, inst.rt, inst.imdExt, inst.rs);
        case Opecode.lui:
            return format!"%-5s $%s, %5s"(inst.ope, inst.rt, inst.imd);
        case Opecode.beq, Opecode.bne:
            return format!"%-5s $%s, $%s, %5s -> %08x"(inst.ope, inst.rs, inst.rt, inst.imdExt, pc + 4 + inst.imdExt * 4);
        case Opecode.j, Opecode.jal:
            return format!"%-5s %08x -> %08x"(inst.ope, inst.adr, ((pc+4) & 0xF0000000) | (inst.adr << 2));
        }
    }
}

uword_t parseNumber(T = uword_t)(in string str)
{
    import std.algorithm: startsWith;
    return str.startsWith("0x")
        ? str[2..$].to!T(16)
        : str.to!T;
}


word_t extendSignHalf(in word_t data) pure nothrow
{
    return (data & 0x00008000)
          ? data | 0xFFFF0000
          : data; 
}

word_t extendSignByte(in word_t data) pure nothrow
{
    return (data & 0x00000080)
          ? data | 0xFFFFFF00
          : data;
}

import std.conv: to;
Opecode   ope(in word_t data) pure         { return to!Opecode(data >>> 26); }
RegId      rs(in word_t data) pure         { return to!RegId((data >>> 21) & 0x1F); }
RegId      rt(in word_t data) pure         { return to!RegId((data >>> 16) & 0x1F); }
RegId      rd(in word_t data) pure         { return to!RegId((data >>> 11) & 0x1F); }
int     shift(in word_t data) pure nothrow { return (data >>> 6) & 0x1F; }
Funct   funct(in word_t data) pure         { return to!Funct(data & 0x3F); }
uword_t   imd(in word_t data) pure nothrow { return data & 0xFFFF; }
word_t imdExt(in word_t data) pure nothrow { return data.imd.extendSignHalf; }
uword_t   adr(in word_t data) pure nothrow { return data & 0x03FFFFFF; }


enum SysCallCode
{
    PrintInteger = 1,
    PrintString = 4,
    ReadInteger = 5,
    ReadString = 8,
    MemoryAllocation = 9,
    Exit = 10,
    PrintChar = 11,
    ReadChar = 12
}


