import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {load} from './load.mjs';
const G=load('Glyphs');
test('every catalog control has a glyph',()=>{
    const cat=JSON.parse(fs.readFileSync(new URL('../controls/catalog.json',import.meta.url),'utf8'));
    for(const c of cat) assert.ok(G.glyph(c.icon || c.id),`no glyph for ${c.id}`);
    assert.equal(G.glyph('not-a-control'),'');
});
