// Post-run file verification only. Never imported by the measured page/harness.
import {readFile,writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import path from 'node:path';
import {analyzeIdentity} from './identity.mjs';
import {analyzeResources} from './resources.mjs';
import {decodeSave,hash} from './codec.mjs';
const evidence=path.resolve(process.argv[2]),root=path.join(evidence,'mac');
const read=async name=>JSON.parse(await readFile(path.join(root,name),'utf8'));
const capture=await read('resource-capture.json'),raw=await read('raw-loop.json'),clocks=await read('resource-clocks.json');
assert.deepEqual(analyzeIdentity(capture),await read('shader-identity-analysis.json'));
assert.deepEqual(analyzeResources(capture,raw,clocks),await read('resource-analysis.json'));
const saves=[];
for(const name of ['save-surface','save-before','save-after']) {
  const bytes=await readFile(path.join(root,name+'.sav')),receipt=await read(name+'.json');
  // The codec deliberately creates null-prototype dictionaries. The harness
  // serializes them to JSON; compare every value after that same JSON boundary.
  const decoded=JSON.parse(JSON.stringify(decodeSave(bytes)));
  assert.deepEqual(decoded,receipt.document);assert.equal(hash(bytes),receipt.sha256);
  saves.push({name,bytes:bytes.length,sha256:hash(bytes),all_decoded_values_equal:true});
}
const receipt={schema:1,resource_analysis_reproduced_exactly:true,identity_analysis_reproduced_exactly:true,saves,
  initial_local_comparison_note:'An earlier ad hoc deepStrictEqual compared codec null-prototype dictionaries directly with parsed JSON objects and rejected their prototype difference. The retained raw save data was unchanged; this verification uses the same serialization boundary as the actual harness and compares every resulting value.'};
await writeFile(path.join(evidence,'closed-analysis-reproduction.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('CLOSED_ACTUAL_IDENTITY_RESOURCE_ANALYSES_AND_THREE_SAVES_REPRODUCED_EXACTLY');
