module mips.assembler.gen;

import std.typecons: Tuple;

import mips.assembler.assm;
import mips.def, mips.assembler.instdef;

int[string] extractLabels(Inst[] insts)
{
    int[string] ret;
    foreach(int idx, inst; insts)
    {
        foreach(l; inst.labels)
        {
            if(l !in ret)
            {
                ret[l] = 4 * idx;
            }
            else
            {
                throw new Exception("Label Duplication: " ~ l);
            }
        }
    }
    return ret;
}


void solveLabels(Inst[] insts, int[string] labels)
{
    foreach(int idx, inst; insts)
    {
        import std.algorithm;
        inst.castSwitch!(
            (InstR i) {},
            (InstI i) {
                if(i.ope.among(Opecode.beq, Opecode.bne) && i.imd.type == typeid(Tuple!(string, bool)))
                {
                    i.imd = Address(labels[i.imd.get!string] / 4 - idx - 1);
                }
                else if(i.ope.among(Opecode.ori, Opecode.bne) && i.imd.type == typeid(Tuple!(string, bool)))
                {}
            },
            (InstJ i) {
                if(i.adr.type == typeid(string))
                {
                    i.adr = Address(labels[i.adr.get!string]);
                }
            }
        );
    }
}
