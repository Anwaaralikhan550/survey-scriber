# usage: python render.py <name>   -> tmp/client-edits-2026-11-13/proof/<name>_pdf_p1.png ... and <name>_word_p1.png ...
import sys, os, subprocess, fitz
root = 'E:/survey-scriber/tmp/client-edits-2026-11-13'
name = sys.argv[1]
src = sys.argv[2] if len(sys.argv) > 2 else f'{root}/out/{name}'
proof = f'{root}/proof'; os.makedirs(proof, exist_ok=True)
def png(pdf, tag, maxp=12):
    d = fitz.open(pdf)
    for i, p in enumerate(d):
        if i >= maxp: break
        p.get_pixmap(dpi=80).save(f'{proof}/{name}_{tag}_p{i+1}.png')
    print(tag, 'pages', len(d))
if os.path.exists(f'{src}.pdf'): png(f'{src}.pdf', 'pdf')
if os.path.exists(f'{src}.docx'):
    wp = f'{src}_word.pdf'
    BS = chr(92)
    subprocess.run(['powershell','-NoProfile','-ExecutionPolicy','Bypass','-File',root+'/word2pdf.ps1',(src+'.docx').replace('/',BS),wp.replace('/',BS)],check=False)
    if os.path.exists(wp): png(wp, 'word')
