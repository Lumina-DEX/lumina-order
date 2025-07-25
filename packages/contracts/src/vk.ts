import { DEXAccountProofProgram, DEXContract, DEXProgram } from "./contracts/index.js";

await DEXProgram.compile();
await DEXAccountProofProgram.compile();
const dexKey = await DEXContract.compile();

console.log("dex key", dexKey.verificationKey.data);
console.log("dex key hash", dexKey.verificationKey.hash.toBigInt());