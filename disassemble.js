let fs = require("fs");
let bytes = fs.readFileSync("Ericsson_P25_vDTMF.BIN");

let hwreg = {
  0x01: "P2_DIR",
  0x03: "P2",
  0x08: "TCSR1",
  0x09: "FRCH",
  0x0a: "FRCL",
  0x0b: "OCR1H",
  0x0c: "OCR1L",
  0x0d: "ICRH",
  0x0e: "ICRL",
  0x0f: "TCSR2",
  0x10: "SCI_RMCR",
  0x11: "SCI_TRCSR",
  0x12: "SCI_RDR",
  0x13: "SCI_TDR",
  0x14: "RAM_P5_CTRL", //also mem
  0x15: "P5",
  0x16: "P6_DIR",
  0x17: "P6",
  0x19: "OCR2H",
  0x1a: "OCR2L",
  0x1b: "TCSR3",
  0x1c: "TCONR",
  0x1d: "T2CNT",
};
// for(let i = 0x040; i < 0x100; i++) {

// }

let instructions = {
  0x01: "nop",
  0x06: "tap",
  0x07: "tpa",
  0x08: "inx",
  0x09: "dex",
  0x0a: "clv",
  0x0b: "sev",
  0x0c: "clc",
  0x0d: "sec",
  0x0e: "cli",
  0x0f: "sei",

  0x10: "sba",
  0x11: "cba",
  0x16: "tab",
  0x17: "tba",
  0x09: "daa",
  0x1b: "aba",

  //branches

  //
  0x30: "tsx",
  0x31: "ins",
  0x32: "pul A",
  0x33: "pul B",
  0x34: "des",
  0x35: "txs",
  0x36: "psh A",
  0x37: "psh B",
  0x39: { op: "rts", arg: "inh", returns: true },
  0x3b: { op: "rti", arg: "inh", returns: true },
  0x3e: "wai",
  0x3f: "swi",

  // 0x86: {
  //   op: "ldaa",
  //   arg: "imm8",
  // },
  0x8e: {
    op: "lds",
    arg: "imm16",
  },
  0xcc: {
    op: "ldd",
    arg: "imm16",
  },

  0xdd: {
    op: "std",
    arg: "dir",
  },
  0xed: {
    op: "std",
    arg: "idx",
  },
  0xfd: {
    op: "std",
    arg: "ext",
  },
  0xce: {
    op: "ldx",
    arg: "imm16",
  },
  0x8c: {
    op: "cpx",
    arg: "imm16",
  },
  0x8d: {
    op: "bsr",
    arg: "rel",
    calls: true,
  },
  0x18: "xgdx",
  0x1a: "slp",
  0x04: "lsrd",
  0x05: "asld",
  0x3a: "abx",
  0x3d: "mul",

  0x83: { op: "subd", arg: "imm16" },
  0x93: { op: "subd", arg: "dir" },
  0xa3: { op: "subd", arg: "idx" },
  0xb3: { op: "subd", arg: "ext" },
  0xc3: { op: "addd", arg: "imm16" },
  0xd3: { op: "addd", arg: "dir" },
  0xe3: { op: "addd", arg: "idx" },
  0xf3: { op: "addd", arg: "ext" },

  0xad: { op: "jsr", arg: "idx", calls: true },
  0xbd: { op: "jsr", arg: "ext_call", calls: true },

  0x61: { op: "aim", arg: "idx3" },
  0x71: { op: "aim", arg: "dir3" },
  0x62: { op: "oim", arg: "idx3" },
  0x72: { op: "oim", arg: "dir3" },
  0x65: { op: "eim", arg: "idx3" },
  0x75: { op: "eim", arg: "dir3" },
  0x6b: { op: "tim", arg: "idx3" },
  0x7b: { op: "tim", arg: "dir3" },
};

//add branches
[
  "bra",
  "brn",
  "bhi",
  "bls",
  "bcc",
  "bcs",
  "bne",
  "beq",
  "bvc",
  "bvs",
  "bpl",
  "bmi",
  "bge",
  "blt",
  "bgt",
  "ble",
].forEach((v, i) => {
  if (!v) return;
  instructions[0x20 | i] = {
    op: v,
    arg: "rel",
  };
});

[
  [
    [1, "a", "b", "idx", "ext"],
    [
      0x40,
      "neg",
      null,
      null,
      "com",
      "lsr",
      null,
      "ror",
      "asr",
      "asl",
      "rol",
      "dec",
      null,
      "inc",
      "tst",
      null,
      "clr",
    ],
  ],
  [
    [01, "idx", "ext"],
    [0x6e, "jmp"],
  ],
  [
    [1, "imm8", "dir", "idx", "ext"],
    [
      0x80,
      "sub A",
      "cmp A",
      "sbc A",
      null,
      "and A",
      "bit A",
      "lda A",
      null,
      "eor A",
      "adc A",
      "ora A",
      "add A",
      "cpx",
      null,
      "lds",
      null,
      0xc0,
      "sub B",
      "cmp B",
      "sbc B",
      null,
      "and B",
      "bit B",
      "lda B",
      null,
      "eor B",
      "adc B",
      "ora B",
      "add B",
      "ldd",
      null,
      "ldx",
      null,
    ],
  ],
  [
    [8, "dir", "idx", "ext"],
    [0x97, "sta A", "sts", 0xd7, "sta B", "stx"],
  ],
].forEach((set) => {
  let start = 0;
  let stride = set[0][0];
  set[1].forEach((v, i) => {
    if (!v) return;
    if (typeof v === "number") {
      start = v - i * stride;
      return;
    }
    for (let j = 1; j < set[0].length; j++) {
      let addr = start + (i - 1) * stride + (j - 1) * 0x10;
      let type = set[0][j];
      // console.log(addr.toString(16), v, type);
      if (instructions[addr]) {
        if (instructions[addr].arg != "imm16") throw v;
        // console.log(v);
        continue;
      }
      switch (type) {
        case "a":
        case "b":
          instructions[addr] = `${v} ${type}`;
          break;
        default:
          instructions[addr] = {
            op: v,
            arg: type,
          };
          break;
      }
    }
  });
});
// console.log(instructions);

let functions = {};
let mem = {};
let labels = {};

let disassemble = (buff, off, addr) => {
  let res = {};
  // let labels = {};
  while (off < buff.length) {
    let opaddr = addr.toString(16).padStart(4, "0");
    let opcode = buff[off++];
    // console.log(opcode.toString(16));
    let info = instructions[opcode];
    if (!info) {
      console.log(
        `Unknown instruction ${buff[off - 1].toString(16)} at ${addr.toString(
          16
        )}`
      );
      return res;
    }
    addr++;
    let instr;
    if (typeof info === "string") {
      instr = info;
    } else {
      if (info.calls) {
        switch (opcode) {
          case 0xbd:
            {
              let funaddr = (buff[off] << 8) | buff[off + 1];
              if (functions[funaddr] == null) {
                functions[funaddr] = {
                  name: `F_${funaddr.toString(16)}`,
                };
                functions[funaddr].data = disassemble(
                  buff,
                  funaddr - 0x8000,
                  funaddr
                );
              }
            }
            break;
          default:
            throw `unsupported jump ${opcode.toString(16)}`;
        }
      }
      switch (info.arg) {
        case "inh":
          instr = `${info.op}`;
          break;
        case "imm16":
          {
            let imm = (buff[off++] << 8) | buff[off++];
            addr += 2;
            instr = `${info.op} 0x${imm.toString(16).padStart(4, "0")}`;
          }
          break;
        case "ext":
          {
            let imm = (buff[off++] << 8) | buff[off++];
            addr += 2;

            if (info.op == "jmp") {
              instr = `${info.op} L_${imm.toString(16).padStart(4, "0")}`;
              if (!labels[imm]) {
                labels[imm] = `L_${imm.toString(16)}`;
                disassemble(buff, imm - 0x8000, imm);
              }
            } else {
              labels[imm] = `D_${imm.toString(16)}`;
              instr = `${info.op} [0x${imm.toString(16).padStart(4, "0")}]`;
            }
          }
          break;
        case "ext_call":
          {
            let imm = (buff[off++] << 8) | buff[off++];
            addr += 2;
            instr = `${info.op} F_${imm.toString(16)}`;
          }
          break;
        case "imm8":
          {
            let imm = buff[off++];
            addr += 1;
            instr = `${info.op} 0x${imm.toString(16)}`;
          }
          break;
        case "dir":
          {
            let imm = buff[off++];
            addr += 1;
            if (hwreg[imm]) {
              imm = hwreg[imm];
            } else imm = `0x${imm.toString(16)}`;
            instr = `${info.op} [${imm}]`;
          }
          break;
        case "dir3":
          {
            let imm = buff[off++];
            let imm2 = buff[off++];
            addr += 2;
            if (hwreg[imm2]) {
              imm2 = hwreg[imm2];
            } else imm2 = `0x${imm2.toString(16)}`;
            instr = `${info.op} 0x${imm.toString(16)} [${imm2}]`;
          }
          break;
        case "idx":
          {
            let imm = buff[off++];
            addr += 1;
            instr = `${info.op} [X + 0x${imm.toString(16)}]`;
          }
          break;
        case "idx3":
          {
            let imm = buff[off++];
            let imm2 = buff[off++];
            addr += 2;
            instr = `${info.op} 0x${imm.toString(16)} [X + 0x${imm2.toString(
              16
            )}]`;
          }
          break;
        case "rel":
          {
            addr += 1;
            let dst = buff.readInt8(off++);
            // let sign = dst >> 7;
            // dst &= 0x3f;
            // if (sign) dst = -dst;
            if (dst > 127) throw "";
            dst += addr;
            instr = `${info.op} L_${dst.toString(16)}`;
            // labels[`L_${dst.toString(16)}`] = dst;
            if (!labels[dst]) {
              labels[dst] = `L_${dst.toString(16)}`;
              disassemble(buff, dst - 0x8000, dst);
            }
          }
          break;
        default:
          throw info.arg;
      }
    }
    res[opaddr] = instr;
    let start = parseInt(opaddr, 16);
    if (mem[start] != undefined && mem[start] != instr) {
      console.log(`uh oh ${opaddr} ${mem[parseInt(opaddr, 16)]} ${instr}`);
    } else {
      mem[start] = instr;
      while (++start < addr) mem[start] = "";
    }
    if (info.returns) return res;
  }
  return res;
};

let ints = [
  ["irq2", 0xffea],
  ["cmi", 0xffec],
  ["trap", 0xffee],
  ["sio", 0xfff0],
  ["toi", 0xfff2],
  ["oci", 0xfff4],
  ["ici", 0xfff6],
  ["irq1", 0xfff8],
  ["swi", 0xfffa],
  ["nmi", 0xfffc],
  ["reset", 0xfffe],
];
ints.forEach((i) => {
  let off = bytes.readUint16BE(i[1] - 0x8000);
  console.log(i[0], off.toString(16));
  functions[off] = {
    name: i[0],
    data: disassemble(bytes, off - 0x8000, off),
  };
});

[0xbcd5, 0x10];
for (let i = 0; i < 0x10; i++) {
  off = 0xbcd5 + 0xa * i;
  functions[off] = {
    name: `jtbl_bcd5_${i}_${off.toString(16)}`,
    data: disassemble(bytes, off - 0x8000, off),
  };
}
[
  /*0x989c,*/ 0xc0ff, 0xc118, 0xc131, 0xc1ae, 0xc1c7, 0xc30c, 0xc325, 0xc33e,
  0xc3bb, 0xc519, 0xc532, 0xc6c2, 0xc6db, 0xc726, 0xc86b,
].forEach((off) => {
  functions[off] = {
    name: `F_UR_${off.toString(16)}`,
    data: disassemble(bytes, off - 0x8000, off),
  };
});
// let reset = bytes.readUInt16BE(0xfffe - 0x8000);
// functions[reset] = { name: "reset", data: disassemble(bytes, 0, reset) };
// console.log();
// console.log();
// console.log(functions);

let output = [];
let includeOff = true;
let lastdb = false;
for (let i = 0x8000; i < 0x10000; i++) {
  if (i >= 0xcd35) break;
  let str = [];
  if (includeOff) str.push(`${i.toString(16)}: `);
  if (functions[i]) {
    str.push(`\n\n${functions[i].name}:`);
  }
  if (labels[i]) str.push(`${labels[i]}:`);
  if (mem[i] != undefined) {
    str.push(`\t${mem[i]}`);
  }
  if (str.length == (includeOff ? 1 : 0)) {
    if (!lastdb) str.push(`D_${i.toString(16)}`);
    str.push(`\t.db $${bytes[i - 0x8000].toString(16).padStart(2, "0")}`);
    lastdb = true;
  } else {
    lastdb = false;
  }
  if (includeOff) str = str[0] + str.slice(1).join("\n");
  else str = str.join("\n");
  if (str!='\t') output.push(str);
}
fs.writeFileSync(`output.asm`, output.join("\n"));

//cd35
