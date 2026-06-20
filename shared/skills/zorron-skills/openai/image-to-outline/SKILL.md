---
name: image-to-outline
description: "Convert any image or illustration into high-quality sketch outlines using optimized Difference of Gaussians (DoG)."
---

# Image to Outline

A powerful, multi-platform agent skill designed to convert any flat illustration, logo, or icon into a clean, noise-free outline sketch using an optimized Difference of Gaussians (DoG) bandpass filter in Python.

## When to use this skill
- When you want to convert flat illustrations, cartoon characters, logos, or user interfaces into high-quality line art / sketch drawings.
- When traditional Canny/Sobel filters fail due to shading gradients, artifacts, or color boundaries.
- **DO NOT invoke when**: Working with complex photographic scenes requiring semantic segmentation (use semantic depth estimation models instead).

## 📦 Prerequisites & Context
- Python 3.9+ installed.
- Global/project dependencies: `numpy` (< 2.0.0 is recommended for PyTorch compatibility, though standalone mode works with 2.x), `pillow`.
- No GPU is required (CPU execution takes less than 1 second per image).

## 🛠 Toolchain
| Tool | Purpose | Constraint |
| :--- | :--- | :--- |
| `Pillow` | Image format conversion, padding, transparency blending, and basic blur filters | Required |
| `NumPy` | Multi-dimensional matrix operations for fast spatial gradient filtering and dilation | Required |

## 📋 Execution Workflow

### Phase 1: Setup Workspace & Dependencies
Create a Python environment and install the required dependencies:
```bash
python3 -m venv venv
source venv/bin/activate
pip install numpy pillow
```

### Phase 2: Process Image to Outline
Execute the bundled `dog_outline.py` script:
```bash
python3 dog_outline.py <input_image_path> <output_image_path> [threshold] [pad] [dilate]
```
- **`threshold`** (default: `40`): Fine-tuning factor. Raise to suppress faint shadows, lower to capture faint details.
- **`pad`** (default: `20`): Surrounding white padding to protect outer boundaries from clipping.
- **`dilate`** (default: `1`): Thickness of the output lines in pixels.

- ✅ **Success**: A high-resolution binary line drawing is saved with clean, anti-aliased black lines on a pure white background.
- 🔄 **Fallback**: If the input image is alpha-transparent and results in black silhouettes, verify that alpha channel pasting onto a white background is enabled (this is default in our helper script).

## ⚠️ Rules & Guardrails
- **MUST**: Always paste transparent RGBA PNG files onto a solid white background of the same size before processing.
- **MUST NOT**: Apply thresholding too early in the processing chain. Always do difference calculation and post-median filtering first to smooth jagged lines.
- **SHOULD**: Add border padding (`pad > 15`) to avoid cropping artifacts near the image boundary.

## 💡 Examples & Edge Cases
### Custom Parameter Configuration
For highly complex logos with fine lines, reduce the threshold and disable dilation:
```bash
python3 dog_outline.py input.png output.png 25 20 0
```
