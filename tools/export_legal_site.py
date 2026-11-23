"""Export the same legal copy bundled in the app to standalone HTML pages."""
import json
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'sites/xike-legal/dist'
EMAIL = 'vqthanh1412489@gmail.com'

def text(value):
    return escape(value).replace(EMAIL, f'<a href="mailto:{EMAIL}">{EMAIL}</a>')

def render(title, content, updated):
    nav = ''.join(f'<a href="/{key}/"'+ (' aria-current="page"' if page['title'] == title else '') + f'>{escape(page["title"])}</a>' for key, page in data['pages'].items())
    return f'''<!doctype html>
<html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{escape(title)} · Xì ke bắc âu</title><meta name="description" content="{escape(title)} của ứng dụng Xì ke bắc âu, do MAX cung cấp."><link rel="stylesheet" href="/style.css"></head>
<body><a class="skip" href="#content">Đến nội dung</a><header><a class="brand" href="/">Xì ke bắc âu</a><span>Thở chậm. Tập an toàn.</span><nav aria-label="Thông tin ứng dụng">{nav}</nav></header>
<main id="content"><p class="eyebrow">THÔNG TIN ỨNG DỤNG · MAX</p><h1>{escape(title)}</h1><p class="updated">Cập nhật: {escape(updated)}</p>{content}</main>
<footer><p>MAX · <a href="mailto:{EMAIL}">{EMAIL}</a></p><p>Ứng dụng hỗ trợ luyện tập và thư giãn thông thường. Không phải thiết bị y tế.</p></footer></body></html>'''

data = json.loads((ROOT / 'assets/legal/content.json').read_text())
DEST.mkdir(parents=True, exist_ok=True)
for slug, page in data['pages'].items():
    directory = DEST / slug
    directory.mkdir(exist_ok=True)
    content = ''.join('<section><h2>' + escape(s['title']) + '</h2>' + ''.join('<p>' + text(p) + '</p>' for p in s['paragraphs']) + '</section>' for s in page['sections'])
    (directory / 'index.html').write_text(render(page['title'], content, data['updated']))
links = ''.join(f'<li><a href="/{slug}/">{escape(page["title"])}</a></li>' for slug, page in data['pages'].items())
(DEST / 'index.html').write_text(render('Chính sách & hỗ trợ', '<p>Thông tin dành cho người sử dụng ứng dụng Xì ke bắc âu.</p><ul class="documents">' + links + '</ul><section><h2>Trước khi luyện tập</h2><p>' + text(data['safety'][0]['paragraphs'][0]) + '</p><p>' + text(data['safety'][1]['paragraphs'][0]) + '</p></section>', data['updated']))
(DEST / 'style.css').write_text('''*{box-sizing:border-box}html{font:17px/1.75 system-ui,-apple-system,sans-serif;color:#332d28;background:#fbf7ed}body{margin:0}a{color:#8a3929;text-underline-offset:.2em}a:focus-visible{outline:3px solid #a4422f;outline-offset:4px}header,main,footer{max-width:840px;margin:auto;padding:28px 24px}header{border-bottom:1px dashed #a39178}header .brand{font:bold 1.55rem/1.4 Georgia,serif;text-decoration:none;color:#332d28}header span{display:block;color:#665c50;margin:4px 0 22px}nav{display:flex;flex-wrap:wrap;gap:12px 24px}nav [aria-current]{font-weight:bold}main{padding-top:48px;padding-bottom:64px}h1,h2{font-family:Georgia,serif;line-height:1.35}h1{font-size:clamp(2rem,6vw,3.1rem);margin:12px 0}h2{font-size:1.4rem;margin-top:0}section{margin-top:28px;padding:24px;background:#fffdf7;border:1px dashed #b5a289;border-radius:16px}p{overflow-wrap:anywhere}section p:last-child{margin-bottom:0}.eyebrow{font-size:.85rem;letter-spacing:.08em;color:#665c50}.updated{color:#665c50}.documents{padding-left:24px}.documents li{margin:16px 0}footer{font-size:.9rem;border-top:1px dashed #a39178;color:#665c50}.skip{position:absolute;top:-100px;left:16px;background:white;padding:12px}.skip:focus{top:10px}@media(max-width:420px){header,main,footer{padding-left:16px;padding-right:16px}section{padding:18px}nav{gap:10px 18px}}''')
print(f'Exported privacy, terms, support and index to {DEST}')
