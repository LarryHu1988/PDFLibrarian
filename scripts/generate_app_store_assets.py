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

EN_FONT = '/System/Library/Fonts/Supplemental/Helvetica.ttc'
CN_FONT = '/System/Library/Fonts/Hiragino Sans GB.ttc'
TITLE_FALLBACK = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf'
LOGO = ASSETS / 'PDFLibrarian-logo-1024.png'

SLIDES = {
    'en-US': [
        {
            'title': 'Search metadata from file names and PDF hints',
            'subtitle': 'Query Google Books, Open Library, Douban, and Library of Congress in one workflow.',
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'title': 'Review and edit Dublin Core fields before write',
            'subtitle': 'Confirm the exact metadata values that should be written back into the selected PDF.',
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'title': 'Rename with the latest written metadata',
            'subtitle': 'Keep file names aligned with the newest confirmed metadata and final rename decisions.',
            'image': ASSETS / 'pdflibrarian-en-light-full.png',
            'theme': 'light',
        },
        {
            'title': 'Built for bilingual and Daylight or Moonlight workflows',
            'subtitle': 'Switch between English and Chinese UI with dedicated light and dark working modes on macOS.',
            'image': ASSETS / 'pdflibrarian-en-dark-full.png',
            'theme': 'dark',
        },
    ],
    'zh-Hans': [
        {
            'title': '根据文件名和 PDF 内容线索检索元数据',
            'subtitle': '在同一流程里查询 Google Books、Open Library、豆瓣和 Library of Congress。',
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'title': '写入前逐项确认并编辑 Dublin Core 字段',
            'subtitle': '先校对元数据，再把最终确认值写回到所选 PDF。',
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'title': '基于最新写入的元数据进行标准重命名',
            'subtitle': '让文件名和刚写入的元数据保持一致，同时保留最终手动修改能力。',
            'image': ASSETS / 'pdflibrarian-zh-Hans-light-full.png',
            'theme': 'light',
        },
        {
            'title': '支持中英文界面与日光 月光工作模式',
            'subtitle': '为长时间整理文献和图书 PDF 设计，适配亮色和暗色桌面环境。',
            'image': ASSETS / 'pdflibrarian-zh-Hans-dark-full.png',
            'theme': 'dark',
        },
    ],
}

PREVIEWS = {
    'en-US': {
        'title': 'PDF Librarian',
        'subtitle': 'Metadata cleanup and rename workflow for book and paper PDFs on macOS.',
    },
    'zh-Hans': {
        'title': 'PDF Librarian',
        'subtitle': '面向 macOS 的书籍与文献 PDF 元数据整理与标准重命名工具。',
    },
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(path, size=size)
    except Exception:
        return ImageFont.truetype(TITLE_FALLBACK, size=size)


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
    d.rounded_rectangle(bbox, radius=220, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    ratio = min(max_w / img.width, max_h / img.height)
    return img.resize((int(img.width * ratio), int(img.height * ratio)), Image.Resampling.LANCZOS)


def chip(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, body_font: ImageFont.FreeTypeFont, fill, stroke, text_fill):
    x, y = xy
    box = draw.textbbox((0, 0), text, font=body_font)
    w = box[2] - box[0] + 42
    h = box[3] - box[1] + 22
    draw.rounded_rectangle((x, y, x + w, y + h), radius=24, fill=fill, outline=stroke, width=2)
    draw.text((x + 21, y + 11 - box[1] / 2), text, font=body_font, fill=text_fill, anchor='lm')
    return w, h


def make_slide(locale: str, idx: int, cfg: dict):
    is_dark = cfg['theme'] == 'dark'
    bg = gradient((W, H), (18, 36, 78) if is_dark else (236, 241, 248), (8, 22, 54) if is_dark else (203, 221, 241))
    canvas = bg.convert('RGBA')
    add_glow(canvas, (-180, -120, 1180, 780), (66, 117, 255, 110 if is_dark else 70), 140)
    add_glow(canvas, (1450, 760, 3200, 2100), (64, 192, 255, 90 if is_dark else 55), 170)

    title_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 118 if locale == 'zh-Hans' else 104)
    subtitle_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 50)
    body_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 34)
    small_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 28)

    draw = ImageDraw.Draw(canvas)
    text_fill = (247, 250, 255) if is_dark else (28, 36, 48)
    sub_fill = (214, 224, 238) if is_dark else (78, 94, 116)

    logo = Image.open(LOGO).convert('RGBA').resize((114, 114), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (178, 126))
    draw.text((314, 144), 'PDF Librarian', font=font(EN_FONT, 52), fill=text_fill)

    title_box = draw.multiline_textbbox((0, 0), cfg['title'], font=title_font, spacing=10)
    draw.multiline_text((180, 320), cfg['title'], font=title_font, fill=text_fill, spacing=10)
    draw.multiline_text((186, 320 + (title_box[3] - title_box[1]) + 38), cfg['subtitle'], font=subtitle_font, fill=sub_fill, spacing=8)

    chip_y = 190
    chip_x = 188
    labels = ['macOS 13+', 'V1.0.0', 'Daylight / Moonlight' if locale == 'en-US' else '日光 / 月光']
    for label in labels:
        w, _ = chip(draw, (chip_x, chip_y), label, small_font,
                    fill=(255, 255, 255, 36) if is_dark else (255, 255, 255, 170),
                    stroke=(255, 255, 255, 70) if is_dark else (130, 150, 180),
                    text_fill=(242, 247, 255) if is_dark else (46, 62, 84))
        chip_x += w + 18

    shot = Image.open(cfg['image']).convert('RGBA')
    shot = fit_image(shot, 1500, 1120)
    shot = rounded(shot, 42)

    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sx, sy = 1180, 510
    shadow_box = Image.new('RGBA', (shot.width + 80, shot.height + 80), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_box)
    shadow_draw.rounded_rectangle((20, 24, shot.width + 52, shot.height + 56), radius=58, fill=(0, 0, 0, 120 if is_dark else 80))
    shadow_box = shadow_box.filter(ImageFilter.GaussianBlur(24))
    shadow.alpha_composite(shadow_box, (sx - 18, sy - 2))
    canvas.alpha_composite(shadow)

    frame = Image.new('RGBA', (shot.width + 24, shot.height + 24), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    frame_fill = (255, 255, 255, 22) if is_dark else (255, 255, 255, 250)
    frame_outline = (255, 255, 255, 72) if is_dark else (180, 196, 220, 255)
    frame_draw.rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), radius=50, fill=frame_fill, outline=frame_outline, width=2)
    frame.alpha_composite(shot, (12, 12))
    canvas.alpha_composite(frame, (sx, sy))

    footer = 'Search • Review • Write • Rename' if locale == 'en-US' else '检索 • 确认 • 写入 • 重命名'
    draw.text((182, 1648), footer, font=body_font, fill=sub_fill)

    out_dir = SCREEN_OUT / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'{idx:02d}.png'
    canvas.convert('RGB').save(out_path, quality=95)
    return out_path


def make_preview(locale: str):
    cfg = PREVIEWS[locale]
    bg = gradient((PW, PH), (236, 241, 248), (204, 222, 242))
    canvas = bg.convert('RGBA')
    add_glow(canvas, (-140, -80, 720, 480), (77, 125, 255, 70), 120)
    add_glow(canvas, (980, 430, 1900, 1180), (0, 157, 255, 68), 140)
    draw = ImageDraw.Draw(canvas)
    title_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 86 if locale == 'zh-Hans' else 82)
    subtitle_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 38)
    body_font = font(CN_FONT if locale == 'zh-Hans' else EN_FONT, 28)

    logo = Image.open(LOGO).convert('RGBA').resize((90, 90), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (104, 88))
    draw.text((214, 98), cfg['title'], font=font(EN_FONT, 46), fill=(27, 37, 52))
    draw.text((104, 238), cfg['subtitle'], font=subtitle_font, fill=(64, 84, 112))

    light = fit_image(Image.open(ASSETS / f'pdflibrarian-{"en" if locale == "en-US" else "zh-Hans"}-light-full.png'), 760, 580)
    dark = fit_image(Image.open(ASSETS / f'pdflibrarian-{"en" if locale == "en-US" else "zh-Hans"}-dark-full.png'), 760, 580)
    light = rounded(light, 28)
    dark = rounded(dark, 28)

    for shot, pos in [(light, (910, 186)), (dark, (1180, 374))]:
        sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
        box = Image.new('RGBA', (shot.width + 50, shot.height + 50), (0, 0, 0, 0))
        dd = ImageDraw.Draw(box)
        dd.rounded_rectangle((14, 18, shot.width + 22, shot.height + 26), radius=38, fill=(0, 0, 0, 90))
        box = box.filter(ImageFilter.GaussianBlur(18))
        sh.alpha_composite(box, (pos[0] - 10, pos[1] - 4))
        canvas.alpha_composite(sh)
        frame = Image.new('RGBA', (shot.width + 16, shot.height + 16), (255, 255, 255, 250))
        frame = rounded(frame, 34)
        frame.alpha_composite(shot, (8, 8))
        canvas.alpha_composite(frame, pos)

    bullets = [
        'Multi-source metadata lookup' if locale == 'en-US' else '多源元数据检索',
        'Editable Dublin Core write' if locale == 'en-US' else '可编辑的 Dublin Core 写入',
        'Consistent library-friendly rename' if locale == 'en-US' else '统一、规范的文件重命名',
    ]
    y = 430
    for item in bullets:
        draw.rounded_rectangle((108, y - 2, 130, y + 20), radius=11, fill=(46, 98, 212))
        draw.text((152, y - 8), item, font=body_font, fill=(32, 48, 72))
        y += 86

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
