module mips.def;

alias word_t = int;
alias uword_t = uint;

enum Opecode
{
    rinst = 0x00,
    addi  = 0x08,
    addiu = 0x09,
    lw    = 0x23,
    lh    = 0x21,
    lhu   = 0x25,
    lb    = 0x20,
    lbu   = 0x24,
    sw    = 0x2B,
    sh    = 0x29,
    sb    = 0x28,
    lui   = 0x0F,
    andi  = 0x0C,
    ori   = 0x0D,
    slti  = 0x0A,
    beq   = 0x04,
    bne   = 0x05,
    j     = 0x02,
    jal   = 0x03,
}

enum Funct
{
    add   = 0x20,
    addu  = 0x21,
    sub   = 0x22,
    subu  = 0x23,
    mult  = 0x18,
    div   = 0x1A,
    divu  = 0x1B,
    mfhi  = 0x10,
    mflo  = 0x12,
    //mfcZ  = 0x,
    //mtcZ  = 0x,
    and   = 0x24,
    or    = 0x25,
    xor   = 0x26,
    nor   = 0x27,
    slt   = 0x2A,
    sll   = 0x00,
    srl   = 0x02,
    sra   = 0x03,
    jr    = 0x08,
    syscall = 0x3F,
}

bool isR(in Opecode m) pure nothrow
{
    return m == Opecode.rinst;
}
bool isJ(in Opecode m) pure nothrow
{
    switch(m)
    {
    case Opecode.j, Opecode.jal:
        return true;
    default:
        return false;
    }
}
bool isI(in Opecode m) pure nothrow { return !m.isR && !m.isJ; }

enum RegId
{
    ze =  0,
    at =  1,
    v0 =  2,
    v1 =  3,
    a0 =  4,
    a1 =  5,
    a2 =  6,
    a3 =  7,
    t0 =  8,
    t1 =  9,
    t2 = 10,
    t3 = 11,
    t4 = 12,
    t5 = 13,
    t6 = 14,
    t7 = 15,
    s0 = 16,
    s1 = 17,
    s2 = 18,
    s3 = 19,
    s4 = 20,
    s5 = 21,
    s6 = 22,
    s7 = 23,
    t8 = 24,
    t9 = 25,
    k0 = 26,
    k1 = 27,
    gp = 28,
    sp = 29,
    fp = 30,
    ra = 31
}

