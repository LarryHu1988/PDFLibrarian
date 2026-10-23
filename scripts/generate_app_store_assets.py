"""Build bilingual release images from production view captures. Run capture_release.sh first."""
from pathlib import Path
import shutil
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[1]
VERSION = "1.5.0"
CAPTURES = ROOT / "dist" / VERSION / "captures"
OUT = ROOT / "docs" / "app-store" / VERSION
FONTS = {"zh-Hans": "/System/Library/Fonts/Hiragino Sans GB.ttc", "en-US": "/System/Library/Fonts/Avenir Next.ttc"}
COPY = {"zh-Hans": ("让每份 PDF，都有清楚的来处。", "导入文件  →  检索书目  →  编辑写入  →  另存命名"), "en-US": ("A proper place for every PDF.", "Import PDFs  →  Find Metadata  →  Edit & Write  →  Save & Rename")}
for locale, (title, subtitle) in COPY.items():
    screenshots = OUT / "screenshots" / locale
    screenshots.mkdir(parents=True, exist_ok=True)
    prefix = "en" if locale == "en-US" else "zh"
    for index, name in [(1,"overview"),(2,"search"),(3,"edit"),(4,"rename"),(5,"warm"),(6,"dark")]:
        source = CAPTURES / locale / f"{index:02d}.png"
        shutil.copy2(source, screenshots / source.name)
        Image.open(source).convert("RGB").resize((1600,1000)).save(ROOT / "docs" / "assets" / f"{prefix}-{name}.webp", quality=92, method=6)
    result = Image.new("RGB", (2400,1760), "#edf3f8")
    draw = ImageDraw.Draw(result)
    icon = Image.open(ROOT / "docs/assets/icon.png").convert("RGBA")
    icon.thumbnail((64,64)); result.paste(icon,(108,72),icon)
    draw.text((190,84), "PDF Librarian", fill="#233348", font=ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc",32))
    draw.text((108,172), title, fill="#172b43", font=ImageFont.truetype(FONTS[locale],66))
    draw.text((108,270), subtitle, fill="#53677d", font=ImageFont.truetype(FONTS[locale],30))
    screen=Image.open(CAPTURES / locale / "03.png").convert("RGB").resize((2184,1365))
    result.paste(screen,(108,350))
    promotional=OUT / "promotional"; promotional.mkdir(parents=True,exist_ok=True)
    result.save(promotional / f"{locale}-workspace.png")
    result.resize((1200,880)).save(ROOT / "docs/assets" / f"social-{locale}.jpg",quality=92)
shutil.copy2(ROOT / "docs/assets/social-en-US.jpg", ROOT / "docs/assets/social.jpg")
print("Prepared 12 screenshots, 12 website views, and bilingual promotional/social images")
