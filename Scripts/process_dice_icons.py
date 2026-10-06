#!/usr/bin/env python3
"""Copy dice icons into Xcode asset catalog (template mode → white in SwiftUI)."""
from pathlib import Path
import json
import shutil

REPO = Path(__file__).resolve().parents[1]
SRC = Path.home() / ".cursor/projects/Users-efecanakbulut-Desktop-Projeler-asdasd/assets"
OUT = REPO / "Scarlight/Assets.xcassets"

ICON_MAP = {
    "dice_oral": "icons8-oral-sex-51-04ab2a71-36d0-4a6f-9ba3-07d5d1f7e240.png",
    "dice_licking": "icons8-licking-51-67927690-ad58-4b49-83cf-3d0f24780e24.png",
    "dice_front": "icons8-front-51-33b250c3-92bb-4b01-a063-091e69a04e19.png",
    "dice_doggy": "icons8-doggy-51-89d07843-6e70-4bde-ae5c-1f075cecc11d.png",
    "dice_cowgirl": "icons8-cowgirl-51-0b8da8df-82ed-4cbd-b658-cd01228069a0.png",
    "dice_back": "icons8-back-51-6448e312-f0b1-4158-b56d-a2eceef19a3d.png",
    "dice_anal": "icons8-anal-51-6fb84f56-61ca-4c6d-8f88-9d0ea817352e.png",
    "dice_standing": "icons8-man-51-1ce6b7fc-d72c-4164-8109-555521678976.png",
    "dice_dog": "icons8-dog-51-2fc1fc85-55b9-4351-8e1b-e50af72b8af7.png",
    "dice_sex": "icons8-sex-51-15b09e09-75f1-4d2d-bdd6-aba5823ce427.png",
}


def write_imageset(name: str, png_name: str) -> None:
    folder = OUT / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    contents = {
        "images": [{"filename": png_name, "idiom": "universal", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "template"},
    }
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for asset_name, filename in ICON_MAP.items():
        src = SRC / filename
        if not src.exists():
            print(f"SKIP missing: {filename}")
            continue
        png_name = f"{asset_name}.png"
        dst = OUT / f"{asset_name}.imageset" / png_name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        write_imageset(asset_name, png_name)
        print(f"OK {asset_name}")


if __name__ == "__main__":
    main()
