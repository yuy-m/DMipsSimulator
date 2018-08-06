module mips.computer.mem;
import mips.def;


struct Regs
{
    private word_t[32] _regs;
    word_t opIndex(in int idx) pure const
    {
        return _regs[idx];
    }
    void opIndexAssign(in word_t val, in int idx) pure
    {
        if(idx != 0)
        {
            _regs[idx] = val;
        }
    }
    void clear() pure
    {
        _regs[] = 0;
        _regs[RegId.sp] = uint.max;
    }
}

struct Memory
{
    private word_t[uint] _mem;

    void clear() pure
    {
        _mem = null;
    }

    alias opIndex = getWord;
    word_t getWord(in uint idx) pure const
    {
        return getHalf(idx)
            | (getHalf(idx + 2) << 16);
    }
    word_t getHalf(in uint idx) pure const
    {
        return getByte(idx)
            | (getByte(idx + 1) << 8);
    }
    word_t getByte(in uint idx) pure const
    {
        if(auto p = idx in _mem)
            return (*p) & 0xFF;
        else
            return 0;
    }

    alias opIndexAssign = setWord;
    void setWord(in word_t val, in uint idx) pure
    {
        setHalf(val, idx);
        setHalf(val >>> 16, idx + 2);
    }
    void setHalf(in word_t val, in uint idx) pure
    {
        setByte(val, idx);
        setByte(val >>> 8, idx + 1);
    }
    void setByte(in word_t val, in uint idx) pure
    {
        _mem[idx] = val & 0xFF;
    }

    alias opSlice = sliceWord;
    alias sliceWord = sliceImpl!getWord;
    alias sliceHalf = sliceImpl!getHalf;
    alias sliceByte = sliceImpl!getByte;
    private word_t[] sliceImpl(alias getM)(in uint b, in uint e) pure const
    {
        word_t[] r;
        foreach(i; b..e)
        {
            r ~= getM(i);
        }
        return r;
    }

    alias sliceCountWord = sliceCountImpl!getWord;
    alias sliceCountHalf = sliceCountImpl!getHalf;
    alias sliceCountByte = sliceCountImpl!getByte;
    private word_t[] sliceCountImpl(alias getM)(in uint b, in uint c) pure const
    {
        import std.algorithm: max, min;
        word_t[] r;
        foreach(i; b.. uint.max - c >= b? b + c: uint.max)
        {
            r ~= getM(i);
        }
        return r;
    }
}
unittest{
    Memory mem;
    mem._mem[0] = 0x99;
    mem._mem[1] = 0x99;
    mem._mem[2] = 0x99;
    mem._mem[3] = 0x99;
    mem.setByte(0x87654321, 0);
    assert(mem.sliceCountByte(0, 4) == [0x21, 0x99, 0x99, 0x99]);

    mem._mem[100] = 0x99;
    mem._mem[101] = 0x99;
    mem._mem[102] = 0x99;
    mem._mem[103] = 0x99;
    mem.setHalf(0x87654321, 100);
    assert(mem.sliceCountByte(100, 4) == [0x21, 0x43, 0x99, 0x99]);

    mem._mem[200] = 0x99;
    mem._mem[201] = 0x99;
    mem._mem[202] = 0x99;
    mem._mem[203] = 0x99;
    mem[200] = 0x87654321;
    assert(mem.sliceCountByte(200, 4) == [0x21, 0x43, 0x65, 0x87]);

    mem._mem[300] = 0x21;
    mem._mem[301] = 0x43;
    mem._mem[302] = 0x65;
    mem._mem[303] = 0x87;
    assert(mem[300] == 0x87654321);
    assert(mem.getHalf(300) == 0x00004321);
    assert(mem.getByte(300) == 0x00000021);
}



