let fs = require("fs");
let bytes = fs.readFileSync("Ericsson_P25_vDTMF.BIN");
let input = fs.readFileSync("out.bin");
for (let i = 0; i < 0x4d35; i++) {
  if (bytes[i] != input[i]) {
    console.log(`Error at ${(i + 0x8000).toString(16)} ${input[i].toString(16)}!=${bytes[i].toString(16)}`);
    process.exit(-1);
  }
}

console.log("Matches.");