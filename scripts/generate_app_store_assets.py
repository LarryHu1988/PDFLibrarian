from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path('/Users/larry/Documents/PDF Librarian')
ASSETS = ROOT / 'docs' / 'assets'
OUT = ROOT / 'docs' / 'app-store'
SCREEN_OUT = OUT / 'screenshots'
PREVIEW_OUT = OUT / 'preview'

W, H = 2880, 1800
PW, PH = 1920, 1080

EN_TITLE_FONT = '/System/Library/Fonts/NewYork.ttf'
EN_BODY_FONT = '/System/Library/Fonts/SFNS.ttf'
CN_TITLE_FONT = '/System/Library/Fonts/Songti.ttc'
CN_BODY_FONT = '/System/Library/Fonts/Hiragino Sans GB.ttc'
FALLBACK_FONT = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf'
LOGO = ASSETS / 'PDFLibrarian-logo-1024.png'

SLIDES = {
    'en-US': [
        {
            'eyebrow': 'PRECISE LOOKUP',
            'title': 'Search metadata from file names and PDF hints',
            'subtitle': 'Query Google Books, Open Library, Douban, and Library of Congress in one focused workflow.',
            'points': [
                'Search title, ISBN, and DOI hints together',
                'Merge public metadata sources in one step',
                'Keep the shortlist clean and ranked',
            ],
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': 'CONTROLLED WRITEBACK',
            'title': 'Review and edit Dublin Core fields before every write',
            'subtitle': 'Confirm the exact values that should be written into the selected PDF before anything changes.',
            'points': [
                'Edit each field before commit',
                'Write only the confirmed values',
                'Preserve a predictable metadata result',
            ],
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': 'RENAME WITH CONTEXT',
            'title': 'Rename using the latest written metadata',
            'subtitle': 'Keep file names aligned with the newest metadata and still allow a final manual rename decision.',
            'points': [
                'Generate names from fresh metadata',
                'Apply one last manual adjustment',
                'Keep the library naming scheme consistent',
            ],
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': 'DESIGNED FOR DAILY USE',
            'title': 'Work in English or Chinese with Daylight and Moonlight modes',
            'subtitle': 'A desktop workflow tuned for long metadata cleanup sessions across bright and dark environments.',
            'points': [
                'Bilingual interface for global libraries',
                'Balanced light and dark working modes',
                'Built for books, papers, and references',
            ],
            'image': ASSETS / 'pdflibrarian-en-dark-full.png',
            'theme': 'dark',
        },
    ],
    'zh-Hans': [
        {
            'eyebrow': '精准检索',
            'title': '根据文件名和 PDF 内容线索检索元数据',
            'subtitle': '在同一流程里查询 Google Books、Open Library、豆瓣和 Library of Congress。',
            'points': [
                '同时识别标题、ISBN 和 DOI 线索',
                '统一合并多个公开元数据来源',
                '保持候选结果清晰且可排序',
            ],
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': '可控写入',
            'title': '写入前逐项确认并编辑 Dublin Core 字段',
            'subtitle': '先校对和修正字段，再把最终确认值写回到所选 PDF。',
            'points': [
                '每个字段都可单独确认',
                '写入严格使用最终编辑值',
                '保证元数据结果可预期',
            ],
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': '标准命名',
            'title': '基于最新写入的元数据进行标准重命名',
            'subtitle': '让文件名和刚写入的元数据保持一致，同时保留最终手动修改能力。',
            'points': [
                '建议文件名来自最新元数据',
                '最终执行前仍可手动修改',
                '统一图书馆式命名规则',
            ],
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'eyebrow': '面向长期整理工作',
            'title': '支持中英文界面与日光 月光工作模式',
            'subtitle': '适合长时间整理文献和图书 PDF，兼顾亮色与暗色桌面环境。',
            'points': [
                '中英文双语界面',
                '日光与月光双模式',
                '适配书籍、论文和参考资料',
            ],
            'image': ASSETS / 'pdflibrarian-zh-Hans-dark-full.png',
            'theme': 'dark',
        },
    ],
}

PREVIEWS = {
    'en-US': {
        'eyebrow': 'PDF LIBRARIAN',
        'title': 'Clean up metadata and rename book and paper PDFs',
        'subtitle': 'Search, confirm, write, and rename with a cleaner desktop workflow on macOS.',
        'points': ['Multi-source lookup', 'Editable Dublin Core write'],
    },
    'zh-Hans': {
        'eyebrow': 'PDF LIBRARIAN',
        'title': '整理书籍与文献 PDF 的元数据并标准重命名',
        'subtitle': '在 macOS 上完成检索、确认、写入和重命名，构建更可维护的资料库。',
        'points': ['多源元数据检索', '可编辑的 Dublin Core 写入'],
    },
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except Exception:
        return ImageFont.truetype(FALLBACK_FONT, size=size)


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new('L', img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.size[0], img.size[1]), radius=radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    img = Image.new('RGB', size)
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = int(top[0] * (1 - t) + bottom[0] * t)
        g = int(top[1] * (1 - t) + bottom[1] * t)
        b = int(top[2] * (1 - t) + bottom[2] * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return img


def add_glow(base: Image.Image, bbox: tuple[int, int, int, int], color: tuple[int, int, int, int], blur: int) -> None:
    layer = Image.new('RGBA', base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(bbox, radius=260, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    ratio = min(max_w / img.width, max_h / img.height)
    return img.resize((int(img.width * ratio), int(img.height * ratio)), Image.Resampling.LANCZOS)


def multiline(draw: ImageDraw.ImageDraw, text: str, font_obj, max_width: int, spacing: int = 8):
    words = text.split(' ')
    if len(words) == 1 and any('\u4e00' <= ch <= '\u9fff' for ch in text):
        units = list(text)
    else:
        units = words
    lines = []
    current = ''
    for unit in units:
        candidate = unit if not current else (current + ('' if units is list(text) else ' ') + unit)
        bbox = draw.multiline_textbbox((0, 0), candidate, font=font_obj, spacing=spacing)
        if bbox[2] - bbox[0] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = unit
    if current:
        lines.append(current)
    return '\n'.join(lines)


def chip(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, body_font, fill, stroke, text_fill):
    x, y = xy
    box = draw.textbbox((0, 0), text, font=body_font)
    w = box[2] - box[0] + 38
    h = box[3] - box[1] + 20
    draw.rounded_rectangle((x, y, x + w, y + h), radius=22, fill=fill, outline=stroke, width=2)
    draw.text((x + 19, y + h / 2), text, font=body_font, fill=text_fill, anchor='lm')
    return w, h


def sanitize_shot(img: Image.Image, is_dark: bool) -> Image.Image:
    shot = img.convert('RGBA').copy()
    d = ImageDraw.Draw(shot)
    fill = (236, 239, 244, 255) if not is_dark else (73, 87, 120, 255)
    stroke = (198, 210, 226, 255) if not is_dark else (99, 113, 150, 255)
    d.rounded_rectangle((86, 780, 228, 840), radius=12, fill=fill, outline=stroke, width=1)
    return shot


def screenshot_panel(shot: Image.Image, is_dark: bool) -> Image.Image:
    frame_pad = 28
    shot = sanitize_shot(shot, is_dark)
    shot = fit_image(shot, 1460, 1040)
    shot = rounded(shot, 34)
    panel = Image.new('RGBA', (shot.width + frame_pad * 2, shot.height + frame_pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(panel)
    fill = (255, 255, 255, 214) if not is_dark else (18, 26, 48, 228)
    stroke = (199, 214, 232, 255) if not is_dark else (76, 96, 136, 255)
    d.rounded_rectangle((0, 0, panel.width - 1, panel.height - 1), radius=44, fill=fill, outline=stroke, width=2)
    panel.alpha_composite(shot, (frame_pad, frame_pad))
    return panel


def draw_text_card(canvas: Image.Image, locale: str, cfg: dict, is_dark: bool, preview: bool = False):
    draw = ImageDraw.Draw(canvas)
    title_font = font(CN_TITLE_FONT if locale == 'zh-Hans' else EN_TITLE_FONT, 64 if preview else 106)
    sub_font = font(CN_BODY_FONT if locale == 'zh-Hans' else EN_BODY_FONT, 28 if preview else 42)
    body_font = font(CN_BODY_FONT if locale == 'zh-Hans' else EN_BODY_FONT, 24 if preview else 31)
    eyebrow_font = font(CN_BODY_FONT if locale == 'zh-Hans' else EN_BODY_FONT, 24 if preview else 26)
    brand_font = font(EN_BODY_FONT, 44 if preview else 48)

    card_x, card_y = (74, 76) if preview else (116, 96)
    card_w, card_h = (720, 930) if preview else (1020, 1520)
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    fill = (255, 255, 255, 188) if not is_dark else (13, 21, 43, 178)
    stroke = (216, 226, 238, 255) if not is_dark else (84, 100, 138, 255)
    d.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=44, fill=fill, outline=stroke, width=2)
    layer = layer.filter(ImageFilter.GaussianBlur(0))
    canvas.alpha_composite(layer)

    logo = Image.open(LOGO).convert('RGBA').resize((94 if preview else 102, 94 if preview else 102), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (card_x + 52, card_y + 48))
    text_fill = (27, 36, 51) if not is_dark else (244, 247, 252)
    sub_fill = (82, 95, 116) if not is_dark else (195, 207, 226)
    accent = (74, 113, 202) if not is_dark else (118, 167, 255)

    draw.text((card_x + 178, card_y + 62), 'PDF Librarian', font=brand_font, fill=text_fill)
    chip(draw, (card_x + 52, card_y + 170), cfg['eyebrow'], eyebrow_font,
         fill=(231, 238, 251, 255) if not is_dark else (34, 52, 88, 255),
         stroke=(196, 213, 239, 255) if not is_dark else (78, 104, 152, 255),
         text_fill=accent)

    title_text = multiline(draw, cfg['title'], title_font, 820 if not preview else 560, spacing=14)
    title_y = card_y + (268 if not preview else 236)
    draw.multiline_text((card_x + 52, title_y), title_text, font=title_font, fill=text_fill, spacing=14)
    title_box = draw.multiline_textbbox((card_x + 52, title_y), title_text, font=title_font, spacing=14)

    sub_text = multiline(draw, cfg['subtitle'], sub_font, 840 if not preview else 570, spacing=10)
    sub_y = title_box[3] + 26
    draw.multiline_text((card_x + 52, sub_y), sub_text, font=sub_font, fill=sub_fill, spacing=10)
    sub_box = draw.multiline_textbbox((card_x + 52, sub_y), sub_text, font=sub_font, spacing=10)

    points_y = sub_box[3] + (58 if not preview else 48)
    for idx, point in enumerate(cfg['points'], start=1):
        dot_x = card_x + 58
        dot_y = points_y + (idx - 1) * (82 if not preview else 74)
        draw.ellipse((dot_x, dot_y, dot_x + 18, dot_y + 18), fill=accent)
        point_text = multiline(draw, point, body_font, 760 if not preview else 510, spacing=6)
        draw.multiline_text((dot_x + 38, dot_y - 9), point_text, font=body_font, fill=text_fill, spacing=6)

    if not preview:
        footer_y = card_y + card_h - 110
        footer_items = ['macOS 13+', 'V1.0.0', 'Dublin Core']
        fx = card_x + 52
        for item in footer_items:
            w, _ = chip(draw, (fx, footer_y), item, eyebrow_font,
                        fill=(255, 255, 255, 220) if not is_dark else (28, 40, 68, 255),
                        stroke=(207, 219, 236, 255) if not is_dark else (78, 100, 142, 255),
                        text_fill=text_fill if not is_dark else (224, 233, 245))
            fx += w + 16


def make_slide(locale: str, idx: int, cfg: dict):
    is_dark = cfg['theme'] == 'dark'
    bg = gradient((W, H), (248, 251, 255) if not is_dark else (10, 18, 42), (216, 228, 246) if not is_dark else (4, 12, 31))
    canvas = bg.convert('RGBA')
    add_glow(canvas, (-260, -120, 980, 760), (104, 149, 255, 90 if not is_dark else 110), 180)
    add_glow(canvas, (1440, 860, 3180, 2140), (38, 167, 255, 72 if not is_dark else 92), 220)

    draw_text_card(canvas, locale, cfg, is_dark, preview=False)

    panel = screenshot_panel(Image.open(cfg['image']), is_dark)
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sx, sy = 1230, 288
    sb = Image.new('RGBA', (panel.width + 80, panel.height + 80), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sb)
    sd.rounded_rectangle((26, 26, panel.width + 30, panel.height + 30), radius=66, fill=(0, 0, 0, 74 if not is_dark else 128))
    sb = sb.filter(ImageFilter.GaussianBlur(26))
    shadow.alpha_composite(sb, (sx - 22, sy + 10))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(panel, (sx, sy))

    out_dir = SCREEN_OUT / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'{idx:02d}.png'
    canvas.convert('RGB').save(out_path, quality=95)
    return out_path


def make_preview(locale: str):
    cfg = PREVIEWS[locale]
    bg = gradient((PW, PH), (248, 251, 255), (215, 228, 244))
    canvas = bg.convert('RGBA')
    add_glow(canvas, (-120, -80, 640, 420), (90, 139, 248, 82), 128)
    add_glow(canvas, (1080, 540, 2040, 1240), (22, 164, 255, 72), 160)

    draw_text_card(canvas, locale, cfg, is_dark=False, preview=True)

    light = screenshot_panel(Image.open(ASSETS / f'pdflibrarian-{"en" if locale == "en-US" else "zh-Hans"}-light-full.png'), False)
    dark = screenshot_panel(Image.open(ASSETS / f'pdflibrarian-{"en" if locale == "en-US" else "zh-Hans"}-dark-full.png'), True)
    light = fit_image(light, 900, 590)
    dark = fit_image(dark, 900, 590)

    def paste_panel(panel: Image.Image, pos: tuple[int, int], shadow_alpha: int):
        sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
        box = Image.new('RGBA', (panel.width + 54, panel.height + 54), (0, 0, 0, 0))
        dd = ImageDraw.Draw(box)
        dd.rounded_rectangle((18, 18, panel.width + 18, panel.height + 18), radius=54, fill=(0, 0, 0, shadow_alpha))
        box = box.filter(ImageFilter.GaussianBlur(18))
        sh.alpha_composite(box, (pos[0] - 12, pos[1] + 4))
        canvas.alpha_composite(sh)
        canvas.alpha_composite(panel, pos)

    paste_panel(light, (980, 132), 68)
    paste_panel(dark, (1120, 430), 92)

    out_dir = PREVIEW_OUT
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'preview-{locale}.png'
    canvas.convert('RGB').save(out_path, quality=95)
    return out_path


def main():
    generated = []
    for locale, slides in SLIDES.items():
        for idx, cfg in enumerate(slides, start=1):
            generated.append(make_slide(locale, idx, cfg))
    for locale in PREVIEWS:
        generated.append(make_preview(locale))
    for path in generated:
        print(path)

if __name__ == '__main__':
    main()
