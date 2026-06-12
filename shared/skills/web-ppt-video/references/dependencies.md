# Dependencies & Command Reference for web-ppt-video

This document lists the official repositories, descriptions, and common command lines for the core dependencies utilized by the `web-ppt-video` skill.

---

## 1. Hyperframes
*   **Repository**: [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes)
*   **Description**: A framework-agnostic, headless-browser-driven HTML to video rendering engine. It boots headless Chrome instances, seeks through target time configurations via custom JS timeline protocols, captures sequential screenshots, and encodes the frames using FFmpeg.

### Common CLI Commands
*   **Render Composition**:
    ```bash
    # Standard render at 30fps
    npx hyperframes render ./my-deck -o ./presentation.mp4 --fps 30
    
    # Render with custom workers (cores limit) and image formatting options
    npx hyperframes render ./my-deck -o ./presentation.mp4 --workers 4 --format jpeg
    ```
*   **Telemetry Controls**:
    ```bash
    # Disable anonymous telemetry tracking
    npx hyperframes telemetry disable
    
    # Enable anonymous telemetry tracking
    npx hyperframes telemetry enable
    ```

---

## 2. guizang-ppt-skill
*   **Repository**: [op7418/guizang-ppt-skill](https://github.com/op7418/guizang-ppt-skill)
*   **Description**: A premium Web-PPT generator by 歸藏, offering two distinct styles: "A: Editorial Magazine" and "B: Swiss Internationalism". It serves as the foundation for the slide structure and component animations before video compilation.

### Core Workflow Integration
1.  **Select & Copy Template**:
    *   Style A: Copy `assets/template.html`
    *   Style B: Copy `assets/template-swiss.html`
2.  **Slide Markup**: Structuring sections with layouts defined in `references/layouts.md` or `references/layouts-swiss.md` and adding `data-layout` and theme markers.

---

## 3. ffmpeg-static & ffprobe-static
*   **npm Packages**:
    *   [ffmpeg-static](https://www.npmjs.com/package/ffmpeg-static)
    *   [ffprobe-static](https://www.npmjs.com/package/ffprobe-static)
*   **Description**: Node.js wrapper modules containing static precompiled binaries of `ffmpeg` and `ffprobe` for various platforms. Essential for sandbox runtimes and developer workspace environments that lack global OS toolchain installations.

### Executable Resolution & Verification
If global installations are missing, retrieve local static paths:
```bash
# Verify static ffmpeg
./node_modules/ffmpeg-static/ffmpeg -version

# Verify static ffprobe (ARM64 macOS Example)
./node_modules/ffprobe-static/bin/darwin/arm64/ffprobe -version
```
To run the render engine with local fallbacks, override the environment `PATH`:
```bash
PATH="./node_modules/ffprobe-static/bin/darwin/arm64:./node_modules/ffmpeg-static:$PATH" npx hyperframes render ./my-deck -o ./presentation.mp4
```
