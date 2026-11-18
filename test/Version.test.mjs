import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
// One version everywhere: the plugin manifest, the status() IPC answer and the settings app package.
test('manifest, status() and the app package report the same version', ()=>{
    const root=new URL('../',import.meta.url);
    const manifest=JSON.parse(readFileSync(new URL('manifest.json',root),'utf8')).version;
    const status=readFileSync(new URL('core/Registry.qml',root),'utf8').match(/JSON\.stringify\(\{version: "([^"]+)"/)[1];
    const pkg=readFileSync(new URL('app/pkgbuild/PKGBUILD',root),'utf8').match(/^pkgver=(\S+)/m)[1];
    assert.equal(status,manifest); assert.equal(pkg,manifest);
});
