from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path('/Users/larry/Documents/PDF Librarian')
ASSETS = ROOT / 'docs' / 'assets'
RAW = ASSETS / 'appstore-raw'
OUT = ROOT / 'docs' / 'app-store'
SCREEN_OUT = OUT / 'screenshots'
PREVIEW_OUT = OUT / 'preview'

W, H = 2880, 1800
PW, PH = 1920, 1080

EN_TITLE_FONT = '/System/Library/Fonts/NewYork.ttf'
EN_BODY_FONT = '/Library/Fonts/SF-Pro.ttf'
CN_TITLE_FONT = '/System/Library/Fonts/Supplemental/Songti.ttc'
CN_BODY_FONT = '/System/Library/Fonts/Hiragino Sans GB.ttc'
MONO_FONT = '/System/Library/Fonts/SFNSMono.ttf'
FALLBACK_FONT = '/System/Library/Fonts/Supplemental/Arial Unicode.ttf'
BRAND_FONT = '/System/Library/Fonts/Avenir Next.ttc'
LOGO = ASSETS / 'PDFLibrarian-logo-1024.png'

SLIDES = {
    'en-US': [
        {
            'eyebrow': 'PRECISE LOOKUP',
            'title': 'Search from filenames\nand PDF clues',
            'subtitle': 'Load a PDF folder, extract title, ISBN, and DOI hints, and start with a focused shortlist.',
            'points': [
                'Scan folders recursively',
                'Read title, ISBN, and DOI hints',
                'Start from a clean shortlist',
            ],
            'image': RAW / 'en-top-light-actual.png',
            'theme': 'light',
        },
        {
            'eyebrow': 'COMPARE SOURCES',
            'title': 'Compare ranked public\nmetadata results',
            'subtitle': 'Review merged candidates from multiple sources before choosing the record that should drive the write.',
            'points': [
                'Merged ranking across sources',
                'Confidence and validation chips',
                'One candidate drives the next step',
            ],
            'image': RAW / 'en-candidates-dark.png',
            'theme': 'dark',
        },
        {
            'eyebrow': 'EDIT BEFORE WRITE',
            'title': 'Review and edit\nmetadata fields',
            'subtitle': 'Check every field before metadata is written back to the selected PDF.',
            'points': [
                'Editable values in place',
                'Selectable field set',
                'Predictable write result',
            ],
            'image': RAW / 'en-edit-dark-actual.png',
            'theme': 'dark',
        },
        {
            'eyebrow': 'RENAME CLEANLY',
            'title': 'Rename from the latest\nwritten metadata',
            'subtitle': 'Use the latest write as the naming source, then keep one final manual edit before rename.',
            'points': [
                'Suggestion from fresh metadata',
                'Final filename stays editable',
                'Cleaner library naming',
            ],
            'image': RAW / 'en-rename-dark-actual.png',
            'theme': 'dark',
            'detail_crop_box': (42, 892, 1935, 1508),
        },
        {
            'eyebrow': 'DAYLIGHT + MOONLIGHT',
            'title': 'Work in English or Chinese\nwith light and dark modes',
            'subtitle': 'A desktop workflow built for long cleanup sessions across bright and dark environments.',
            'points': [
                'English and Chinese UI',
                'Daylight and Moonlight modes',
                'Polished for daily library work',
            ],
            'image': RAW / 'en-top-dark-actual.png',
            'theme': 'dark',
        },
    ],
    'zh-Hans': [
        {
            'eyebrow': '精准检索',
            'title': '文件名与线索\n驱动精准检索',
            'subtitle': '加载 PDF 后统一提取标题、ISBN 与 DOI 线索，再开始联机检索。',
            'points': [
                '递归扫描文件夹中的 PDF',
                '自动提取标题与编号线索',
                '从干净候选集开始筛选',
            ],
            'image': RAW / 'zh-top-light-actual.png',
            'theme': 'light',
        },
        {
            'eyebrow': '候选对比',
            'title': '对比多来源\n候选元数据',
            'subtitle': '先看候选结果与置信度，再决定哪条记录进入写入流程。',
            'points': [
                '跨来源合并与排序',
                '带置信度与来源标记',
                '选定后进入确认写入',
            ],
            'image': RAW / 'zh-candidates-dark.png',
            'theme': 'dark',
        },
        {
            'eyebrow': '写入前确认',
            'title': '写入前确认并\n编辑元数据字段',
            'subtitle': '逐项查看并修改字段内容，确保写回 PDF 的就是最终确认值。',
            'points': [
                '字段可逐项编辑',
                '仅写入最终确认值',
                '写入结果更可预期',
            ],
            'image': RAW / 'zh-edit-dark-actual.png',
            'theme': 'dark',
        },
        {
            'eyebrow': '标准命名',
            'title': '基于最新元数据\n统一文件命名',
            'subtitle': '按刚写入的元数据生成建议文件名，并保留最后一次手动修改。',
            'points': [
                '建议名来自最新元数据',
                '最终文件名仍可改',
                '统一资料库命名规则',
            ],
            'image': RAW / 'zh-rename-dark-actual.png',
            'theme': 'dark',
            'detail_crop_box': (42, 892, 1935, 1508),
        },
        {
            'eyebrow': '双语与双模式',
            'title': '支持中英双语与\n日光、月光模式',
            'subtitle': '适合长时间整理图书和文献 PDF，同时兼顾亮色与暗色桌面环境。',
            'points': [
                '中英文界面',
                '日光与月光模式',
                '适合书籍、论文与参考资料',
            ],
            'image': RAW / 'zh-top-dark-actual.png',
            'theme': 'dark',
        },
    ],
}

PREVIEWS = {
    'en-US': {
        'eyebrow': 'PDF LIBRARIAN',
        'title': 'Clean metadata\nRename with context',
        'subtitle': 'Search, confirm, write, and rename in one calmer desktop workflow.',
        'points': ['Multi-source lookup', 'Editable Dublin Core write'],
    },
    'zh-Hans': {
        'eyebrow': 'PDF LIBRARIAN',
        'title': '整理元数据\n统一命名',
        'subtitle': '完成检索、确认、写入与重命名，让资料库更整洁',
        'points': ['多源检索', '可编辑写入'],
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
    d.rounded_rectangle(bbox, radius=240, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(layer)


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    ratio = min(max_w / img.width, max_h / img.height)
    return img.resize((int(img.width * ratio), int(img.height * ratio)), Image.Resampling.LANCZOS)


def contains_cjk(text: str) -> bool:
    return any('\u4e00' <= ch <= '\u9fff' for ch in text)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font_obj, max_width: int, spacing: int = 8) -> str:
    lines: list[str] = []
    for para in text.split('\n'):
        if not para:
            lines.append('')
            continue
        cjk = contains_cjk(para)
        units = list(para) if cjk else para.split(' ')
        joiner = '' if cjk else ' '
        current = ''
        for unit in units:
            candidate = unit if not current else current + joiner + unit
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
    w = box[2] - box[0] + 34
    h = box[3] - box[1] + 18
    draw.rounded_rectangle((x, y, x + w, y + h), radius=20, fill=fill, outline=stroke, width=2)
    draw.text((x + 17, y + h / 2), text, font=body_font, fill=text_fill, anchor='lm')
    return w, h


def trim_window_frame(img: Image.Image) -> Image.Image:
    rgb = img.convert('RGB')
    px = rgb.load()
    min_x, min_y = rgb.width, rgb.height
    max_x, max_y = 0, 0
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            if r > 18 or g > 18 or b > 18:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x <= min_x or max_y <= min_y:
        return img
    pad = 6
    return img.crop((max(min_x - pad, 0), max(min_y - pad, 0), min(max_x + pad, img.width), min(max_y + pad, img.height)))


def prepare_shot(img: Image.Image, crop_box: tuple[int, int, int, int] | None = None) -> Image.Image:
    shot = trim_window_frame(img).convert('RGBA')
    if crop_box:
        shot = shot.crop(crop_box)
    return shot


def screenshot_panel(shot: Image.Image, is_dark: bool) -> Image.Image:
    frame_pad = 28
    shot = shot.convert('RGBA')
    shot = fit_image(shot, 1460, 1040)
    shot = rounded(shot, 34)
    panel = Image.new('RGBA', (shot.width + frame_pad * 2, shot.height + frame_pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(panel)
    fill = (255, 255, 255, 216) if not is_dark else (18, 26, 48, 232)
    stroke = (199, 214, 232, 255) if not is_dark else (76, 96, 136, 255)
    d.rounded_rectangle((0, 0, panel.width - 1, panel.height - 1), radius=44, fill=fill, outline=stroke, width=2)
    panel.alpha_composite(shot, (frame_pad, frame_pad))
    return panel


def screenshot_detail_panel(shot: Image.Image, is_dark: bool, max_w: int = 1060, max_h: int = 560) -> Image.Image:
    shot = fit_image(shot.convert('RGBA'), max_w, max_h)
    shot = rounded(shot, 30)
    panel = Image.new('RGBA', (shot.width + 24, shot.height + 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(panel)
    fill = (255, 255, 255, 206) if not is_dark else (17, 26, 47, 242)
    stroke = (202, 217, 238, 255) if not is_dark else (77, 100, 145, 255)
    d.rounded_rectangle((0, 0, panel.width - 1, panel.height - 1), radius=34, fill=fill, outline=stroke, width=2)
    panel.alpha_composite(shot, (12, 12))
    return panel


def draw_text_card(canvas: Image.Image, locale: str, cfg: dict, is_dark: bool, preview: bool = False):
    draw = ImageDraw.Draw(canvas)
    if locale == 'zh-Hans':
        title_font = font(CN_TITLE_FONT, 60 if preview else 92)
        sub_font = font(CN_BODY_FONT, 25 if preview else 38)
        body_font = font(CN_BODY_FONT, 23 if preview else 29)
        eyebrow_font = font(CN_BODY_FONT, 20 if preview else 22)
    else:
        title_font = font(EN_TITLE_FONT, 64 if preview else 98)
        sub_font = font(EN_BODY_FONT, 28 if preview else 39)
        body_font = font(EN_BODY_FONT, 23 if preview else 29)
        eyebrow_font = font(EN_BODY_FONT, 20 if preview else 22)
    brand_font = font(BRAND_FONT, 44 if preview else 48)

    card_x, card_y = (74, 76) if preview else (112, 96)
    card_w, card_h = (720, 930) if preview else (1010, 1520)
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    fill = (255, 255, 255, 196) if not is_dark else (9, 18, 39, 188)
    stroke = (222, 231, 241, 255) if not is_dark else (72, 93, 134, 255)
    d.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=48, fill=fill, outline=stroke, width=2)
    d.line((card_x + 50, card_y + 214, card_x + card_w - 50, card_y + 214),
           fill=(228, 233, 242, 255) if not is_dark else (42, 59, 94, 255), width=2)
    canvas.alpha_composite(layer)

    logo = Image.open(LOGO).convert('RGBA').resize((94 if preview else 102, 94 if preview else 102), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (card_x + 50, card_y + 48))
    text_fill = (24, 34, 51) if not is_dark else (244, 247, 252)
    sub_fill = (88, 100, 120) if not is_dark else (196, 208, 228)
    accent = (72, 110, 210) if not is_dark else (112, 166, 255)

    draw.text((card_x + 176, card_y + 60), 'PDF Librarian', font=brand_font, fill=text_fill)
    chip(draw, (card_x + 50, card_y + 158), cfg['eyebrow'], eyebrow_font,
         fill=(231, 238, 251, 255) if not is_dark else (34, 52, 88, 255),
         stroke=(196, 213, 239, 255) if not is_dark else (78, 104, 152, 255),
         text_fill=accent)

    title_spacing = 14 if locale == 'zh-Hans' else 12
    title_text = wrap_text(draw, cfg['title'], title_font, 820 if not preview else 560, spacing=title_spacing)
    title_y = card_y + (266 if not preview else 236)
    draw.multiline_text((card_x + 50, title_y), title_text, font=title_font, fill=text_fill, spacing=title_spacing)
    title_box = draw.multiline_textbbox((card_x + 50, title_y), title_text, font=title_font, spacing=title_spacing)

    sub_text = wrap_text(draw, cfg['subtitle'], sub_font, 840 if not preview else 570, spacing=10)
    sub_y = title_box[3] + 28
    draw.multiline_text((card_x + 50, sub_y), sub_text, font=sub_font, fill=sub_fill, spacing=10)
    sub_box = draw.multiline_textbbox((card_x + 50, sub_y), sub_text, font=sub_font, spacing=10)

    points_y = sub_box[3] + (54 if not preview else 42)
    step = 78 if not preview else 68
    for idx, point in enumerate(cfg['points'], start=1):
        dot_x = card_x + 54
        dot_y = points_y + (idx - 1) * step
        draw.ellipse((dot_x, dot_y + 4, dot_x + 16, dot_y + 20), fill=accent)
        point_text = wrap_text(draw, point, body_font, 760 if not preview else 510, spacing=6)
        draw.multiline_text((dot_x + 36, dot_y), point_text, font=body_font, fill=text_fill, spacing=6)

    if not preview:
        footer_y = card_y + card_h - 110
        footer_items = ['macOS 13+', 'V1.0.0', 'Dublin Core']
        fx = card_x + 50
        for item in footer_items:
            w, _ = chip(draw, (fx, footer_y), item, eyebrow_font,
                        fill=(255, 255, 255, 220) if not is_dark else (28, 40, 68, 255),
                        stroke=(207, 219, 236, 255) if not is_dark else (78, 100, 142, 255),
                        text_fill=text_fill if not is_dark else (224, 233, 245))
            fx += w + 14


def draw_preview_copy(canvas: Image.Image, locale: str, cfg: dict):
    draw = ImageDraw.Draw(canvas)
    if locale == 'zh-Hans':
        title_font = font(CN_TITLE_FONT, 78)
        sub_font = font(CN_BODY_FONT, 31)
        body_font = font(CN_BODY_FONT, 25)
        eyebrow_font = font(CN_BODY_FONT, 19)
    else:
        title_font = font(EN_TITLE_FONT, 72)
        sub_font = font(EN_BODY_FONT, 29)
        body_font = font(EN_BODY_FONT, 24)
        eyebrow_font = font(EN_BODY_FONT, 19)
    brand_font = font(BRAND_FONT, 46)

    x = 88
    logo = Image.open(LOGO).convert('RGBA').resize((98, 98), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, (x, 84))
    text_fill = (28, 38, 56)
    sub_fill = (92, 104, 124)
    accent = (84, 122, 220)
    divider = (219, 226, 236)

    draw.text((x + 122, 96), 'PDF Librarian', font=brand_font, fill=text_fill)
    chip(draw, (x, 202), cfg['eyebrow'], eyebrow_font,
         fill=(232, 239, 252, 255),
         stroke=(196, 213, 239, 255),
         text_fill=accent)
    draw.line((x, 248, x + 620, 248), fill=divider, width=2)

    title = wrap_text(draw, cfg['title'], title_font, 620, spacing=12 if locale != 'zh-Hans' else 16)
    title_y = 286
    title_spacing = 12 if locale != 'zh-Hans' else 16
    draw.multiline_text((x, title_y), title, font=title_font, fill=text_fill, spacing=title_spacing)
    title_box = draw.multiline_textbbox((x, title_y), title, font=title_font, spacing=title_spacing)

    subtitle = wrap_text(draw, cfg['subtitle'], sub_font, 640, spacing=10)
    sub_y = title_box[3] + 24
    draw.multiline_text((x, sub_y), subtitle, font=sub_font, fill=sub_fill, spacing=10)
    sub_box = draw.multiline_textbbox((x, sub_y), subtitle, font=sub_font, spacing=10)

    point_y = sub_box[3] + 54
    for idx, point in enumerate(cfg['points']):
        py = point_y + idx * 68
        draw.ellipse((x + 2, py + 10, x + 18, py + 26), fill=accent)
        draw.text((x + 36, py), point, font=body_font, fill=text_fill)


def load_slide_image(locale: str, cfg: dict, is_dark: bool) -> Image.Image:
    img = Image.open(cfg['image'])
    return prepare_shot(img, cfg.get('crop_box'))


def make_slide(locale: str, idx: int, cfg: dict):
    is_dark = cfg['theme'] == 'dark'
    if not is_dark:
        bg = gradient((W, H), (249, 251, 255), (216, 229, 246))
        glow_a = (104, 149, 255, 82)
        glow_b = (38, 167, 255, 66)
    else:
        bg = gradient((W, H), (9, 18, 42), (3, 10, 28))
        glow_a = (98, 136, 255, 118)
        glow_b = (18, 170, 255, 92)
    canvas = bg.convert('RGBA')
    add_glow(canvas, (-260, -120, 960, 760), glow_a, 180)
    add_glow(canvas, (1400, 860, 3180, 2140), glow_b, 220)

    draw_text_card(canvas, locale, cfg, is_dark, preview=False)

    shot = load_slide_image(locale, cfg, is_dark)
    panel = screenshot_panel(shot, is_dark)
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    sx, sy = 1230, 286
    if 'detail_crop_box' in cfg:
        panel = fit_image(panel, 1120, 880)
        sx, sy = 1360, 166
    sb = Image.new('RGBA', (panel.width + 84, panel.height + 84), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sb)
    sd.rounded_rectangle((26, 26, panel.width + 28, panel.height + 28), radius=66, fill=(0, 0, 0, 72 if not is_dark else 128))
    sb = sb.filter(ImageFilter.GaussianBlur(24))
    shadow.alpha_composite(sb, (sx - 24, sy + 14))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(panel, (sx, sy))

    if 'detail_crop_box' in cfg:
        detail = prepare_shot(Image.open(cfg['image']), cfg['detail_crop_box'])
        detail_panel = screenshot_detail_panel(detail, True, max_w=1150, max_h=430)
        dx, dy = 1480, 980
        sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
        box = Image.new('RGBA', (detail_panel.width + 66, detail_panel.height + 66), (0, 0, 0, 0))
        dd = ImageDraw.Draw(box)
        dd.rounded_rectangle((20, 20, detail_panel.width + 20, detail_panel.height + 20), radius=54, fill=(0, 0, 0, 118))
        box = box.filter(ImageFilter.GaussianBlur(18))
        sh.alpha_composite(box, (dx - 12, dy + 8))
        canvas.alpha_composite(sh)
        canvas.alpha_composite(detail_panel, (dx, dy))

    out_dir = SCREEN_OUT / locale
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'{idx:02d}.png'
    canvas.convert('RGB').save(out_path, quality=95)
    return out_path


def make_preview(locale: str):
    cfg = PREVIEWS[locale]
    bg = gradient((PW, PH), (250, 251, 255), (220, 231, 244))
    canvas = bg.convert('RGBA')
    add_glow(canvas, (1160, 520, 2060, 1240), (32, 164, 255, 54), 188)
    add_glow(canvas, (1180, 620, 2140, 1320), (100, 136, 248, 48), 210)

    draw_preview_copy(canvas, locale, cfg)

    light_source = RAW / ('en-top-light-actual.png' if locale == 'en-US' else 'zh-top-light-actual.png')
    dark_source = RAW / ('en-rename-dark-actual.png' if locale == 'en-US' else 'zh-rename-dark-actual.png')
    light = screenshot_panel(prepare_shot(Image.open(light_source)), False)
    dark = screenshot_detail_panel(prepare_shot(Image.open(dark_source), (42, 892, 1935, 1508)), True, max_w=760, max_h=330)
    light = fit_image(light, 820, 548)
    dark = fit_image(dark, 720, 312)

    def paste_panel(panel: Image.Image, pos: tuple[int, int], shadow_alpha: int):
        sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
        box = Image.new('RGBA', (panel.width + 54, panel.height + 54), (0, 0, 0, 0))
        dd = ImageDraw.Draw(box)
        dd.rounded_rectangle((18, 18, panel.width + 18, panel.height + 18), radius=54, fill=(0, 0, 0, shadow_alpha))
        box = box.filter(ImageFilter.GaussianBlur(18))
        sh.alpha_composite(box, (pos[0] - 12, pos[1] + 4))
        canvas.alpha_composite(sh)
        canvas.alpha_composite(panel, pos)

    paste_panel(light, (1040, 116), 62)
    paste_panel(dark, (1168, 610), 82)

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
