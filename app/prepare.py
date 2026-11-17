from pathlib import Path
import shutil
root=Path(__file__).resolve().parent
out=root/'generated'
for folder, names in {'logic':['ConfigSchema.js','ConfigMigrate.js','Labels.js','Geometry.js','Layout.js','Glyphs.js'],'controls':['catalog.json']}.items():
    (out/folder).mkdir(parents=True,exist_ok=True)
    for name in names: shutil.copyfile(root.parent/folder/name,out/folder/name)
files=[(p.relative_to(out).as_posix(),p) for p in out.rglob('*') if p.is_file()]
files += [('agent-SKILL.md',root/'agent-SKILL.md')]
files += [('qml/'+p.name,p) for p in (root/'qml').glob('*.qml')]
(root/'resources.qrc').write_text('<RCC><qresource prefix="/">'+''.join(f'<file alias="{alias}">{p.relative_to(root)}</file>' for alias,p in files)+'</qresource></RCC>')
