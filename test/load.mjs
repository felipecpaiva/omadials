import {readFileSync} from 'node:fs';
export function load(name) {
    const source=readFileSync(new URL(`../logic/${name}.js`,import.meta.url),'utf8');
    const names=[...source.matchAll(/^(?:const|function)\s+(\w+)/gm)].map(m=>m[1]);
    return new Function(source.replace(/^\.pragma library\s*\n/,'')+`;return {${names.join(',')}};`)();
}
