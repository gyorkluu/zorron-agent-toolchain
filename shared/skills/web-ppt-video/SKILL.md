---
name: web-ppt-video
description: "Generate web-based interactive presentations (PPT) in HTML and render them into dynamic MP4 videos using Hyperframes. Trigger this skill when the user wants to build professional slide decks with smooth animations or convert HTML slide presentations into videos with slide transitions and content entry animations. DO NOT invoke this skill for generating offline PPTX files, plain Markdown documents without slides, or generic video editing tasks."
version: 1.0.0
argument-hint: <input> [--dry-run]
allowed-tools: [Read, Write, Bash]
---

# Web PPT and Video Rendering Skill

A specialized skill to assist in structuring interactive web presentations (HTML slides) and rendering them into dynamic MP4 videos using the Hyperframes headless render engine.

## When to invoke

- **Use this skill** when the user wants to generate, modify, or enhance interactive HTML-based presentations with slide transition and component entrance animations.
- **Use this skill** when the user wants to convert an HTML slide deck into a dynamic, frame-perfect MP4 video using `@hyperframes/cli` or similar tools.
- **Use this skill** when troubleshooting rendering issues such as videos getting stuck on the first page, animations not playing, timeline timeouts, or headless browser crash diagnostics.
- **DO NOT invoke this skill** when the user requests standard Microsoft PowerPoint files (`.pptx`), static PDF exports, plain-text outlines, or general video/audio processing unrelated to HTML rendering.

## 📦 Prerequisites & Context

- **Runtime**: Node.js ≥ 18, Python ≥ 3.10
- **Dependencies**: `@hyperframes/cli` (installed globally or locally in project node_modules). See [dependencies.md](references/dependencies.md) for GitHub repos and command reference.
- **External Binaries**: `ffmpeg` and `ffprobe` (for video compiling). In constrained environments (such as developer sandboxes), static node packages like `ffmpeg-static` and `ffprobe-static` are used.
- **Related Skills**: `guizang-ppt-skill` (used to generate the premium horizontal slides).


## 🛠 Toolchain & Auto-Setup

Before executing any commands, the Agent should run the environment check script [setup-env.sh](scripts/setup-env.sh) to detect, verify, and automatically install the required dependencies:

```bash
# Execute the environment setup check from the skill root directory
./scripts/setup-env.sh
```

This script will verify Node.js, detect if `guizang-ppt-skill` is in the active skill fold, verify if `@hyperframes/cli` is present, check for global `ffmpeg`/`ffprobe` installations, and automatically fall back to installing local Node.js static binaries (`ffmpeg-static` and `ffprobe-static`) in the local workspace if the global utilities are not available.

## 📋 Execution Workflow

### Phase 1: Environment Check & Installation
1. Check the local environment for `ffmpeg`, `ffprobe`, `@hyperframes/cli`, and `guizang-ppt-skill` using [setup-env.sh](scripts/setup-env.sh).
2. If dependencies (like static binaries) are missing, execute local installations (`pnpm add -D ffmpeg-static ffprobe-static @hyperframes/cli`) to set up a sandboxed environment automatically.
- ✅ Success: Environment checks pass, dependencies are fully installed, and compile binaries are ready.
- 🔄 Fallback: If local installation fails, prompt the user to install dependencies (e.g. `brew install ffmpeg`) or choose a global fallback path.

### Phase 2: Interactive Slide Pre-flight Design
1. Define a stable container `#stage` for the presentation composition, containing required attributes:
   ```html
   <div id="stage" data-composition-id="slide-deck-id" data-width="1920" data-height="1080" data-root="true">
   ```
2. Design custom transitions (e.g. horizontal/vertical sliding of the `#deck` container) using standard CSS or JS animations.
3. Expose the slide deck's state variables (like slide index, active states) globally on the `window` context by using `var` instead of block-scoped `let` or `const` (e.g., `var lock = false;`). This allows external seek controllers to manipulate navigation state.
- ✅ Success: The HTML presentation is fully interactive in standard browsers and exposes global slide index properties.
- 🔄 Fallback: If slide navigation fails, inspect the browser's developer console for variable reference and scoping errors.

### Phase 3: Hyperframe Rendering Integration
1. Set up the `window.__hf` seek protocol interface:
   ```javascript
   window.__hf = {
     duration: 36, // Total video duration in seconds (e.g., 9 slides * 4s)
     seek(t) {
       transitionToPage(t);
     }
   };
   ```
2. Initialize `window.__timelines` registry to prevent Hyperframe engine startup timeouts:
   ```javascript
   window.__timelines = window.__timelines || {};
   window.__timelines['slide-deck-id'] = {
     getChildren: () => [],
     pause() {},
     play() {},
     seek(t) {
       transitionToPage(t);
     }
   };
   ```
3. Implement robust `window.__player` hijacking to intercept the engine's frame-seek commands:
   ```javascript
   function hookPlayer(val) {
     if (val && typeof val.renderSeek === 'function' && !val.__hijacked) {
       val.__hijacked = true;
       const origRenderSeek = val.renderSeek;
       val.renderSeek = function(t) {
         origRenderSeek.call(val, t);
         transitionToPage(t);
       };
     }
   }
   if (window.__player) hookPlayer(window.__player);
   let realPlayer = window.__player;
   Object.defineProperty(window, '__player', {
     configurable: true,
     enumerable: true,
     get() { return realPlayer; },
     set(val) {
       realPlayer = val;
       hookPlayer(val);
     }
   });
   ```
- ✅ Success: The seeking mechanism captures page boundary changes and triggers the appropriate slide navigation.
- 🔄 Fallback: Ensure no dynamic imports (e.g. `import('./assets/motion.min.js')`) are used, as dynamic ESM imports fail over local `file://` protocols in headless mode. Bundle libraries inline or as static assets instead.

### Phase 4: Headless Capturing & Encoding
1. Resolve binary paths (e.g. `node_modules/ffmpeg-static` and `node_modules/ffprobe-static/bin/darwin/arm64` if using local fallback).
2. Run the compiler render command with the injected paths:
   ```bash
   PATH="/path/to/project/node_modules/ffprobe-static/bin/darwin/arm64:/path/to/project/node_modules/ffmpeg-static:$PATH" npx hyperframes render /path/to/ppt-dir -o /path/to/output/presentation.mp4
   ```
- ✅ Success: The CLI successfully boots headless Chrome instances, seeks through each frame, and outputs the encoded MP4.
- 🔄 Fallback: If rendering fails, check browser log console outputs and verify that the target HTML is fully offline-compliant.

## ⚠️ Rules & Guardrails

- **MUST NOT** load external typography (e.g. Google Fonts CDN) or remote assets in the slides, as sandboxed/headless render runs may operate offline or block external assets. Use local `@font-face` definitions.
- **MUST** disable high-performance canvas loop loops (WebGL fluid backgrounds, ASCII canvas simulations) when rendering to avoid CPU throttling. Dispatch custom events (e.g., `swiss-low-power-change`) to stop RAF loops when `window.__hyperframesMode` is enabled.
- **MUST** run a debouncer check in the slide seek script to ensure slide transitions are only called when the target index changes, avoiding re-triggering the transition animation on every frame.

## ⚠️ Gotchas & Tricky Details (常踩的坑)

### 1. Timeline Bridge Override (Timeline Overwrite)
The Hyperframe engine injects its own bridge script `HF_BRIDGE_SCRIPT` right before `</body>`, which can override standard seek registries. Defining both `window.__hf.seek` and hijacking the `__player.renderSeek` setter ensures that no matter when the engine binds the player, the frame seeks are correctly routed to the slide transition function.

### 2. Playback vs Scrubbing in Headless Renders
Standard CSS transitions and `setTimeout` timers are non-deterministic and do not follow the frame capture clock. To capture entrance animations:
- When in render mode (`window.__hyperframesMode = true`), disable layout CSS transitions (`transition: none !important`) on the slide container.
- Pause all Web Animations and manually set their `.currentTime` based on slide progression:
  ```javascript
  const animTimeMs = Math.max(0, (t - (slideStart + 0.45)) * 1000);
  document.getAnimations().forEach(anim => {
    anim.pause();
    anim.currentTime = animTimeMs;
  });
  ```

### 3. File Protocol CORS Restrictions
Dynamic imports of local ESM files (e.g., `import('./motion.min.js')`) fail on local `file://` URLs in Chrome due to CORS blocks. Inject scripts as traditional scripts (global variables, e.g., `window.Motion`) rather than dynamically importing modules.

## 💡 Examples & Edge Cases

### Example 1: Full transitionToPage Implementation
Here is the recommended script template to inject at the end of the interactive PPT `index.html`:

```html
<script>
(function() {
  function solveCubicBezier(x1, y1, x2, y2) {
    return function(t) {
      let x = t;
      for (let i = 0; i < 8; i++) {
        let currentX = 3 * (1 - x) * (1 - x) * x * x1 + 3 * (1 - x) * x * x * x2 + x * x * x;
        let derivative = 3 * (1 - x) * (1 - x) * x1 + 6 * (1 - x) * x * (x2 - x1) + 3 * x * x * (1 - x2);
        if (Math.abs(derivative) < 1e-6) break;
        x -= (currentX - t) / derivative;
      }
      return 3 * (1 - x) * (1 - x) * x * y1 + 3 * (1 - x) * x * x * y2 + x * x * x;
    };
  }
  const easeBezier = solveCubicBezier(0.77, 0, 0.175, 1);

  function transitionToPage(t) {
    window.__hyperframesMode = true;
    
    // Hide resource-intensive WebGL elements and pause their animation frames
    if (!document.body.classList.contains('render-video')) {
      document.body.classList.add('render-video');
      document.body.classList.remove('low-power');
      dispatchEvent(new CustomEvent('swiss-low-power-change', { detail: { on: true } }));
      document.querySelectorAll('canvas.bg, canvas.ascii-bg').forEach(c => c.style.display = 'none');
    }

    const totalSlides = 9;
    const slideDuration = 4; // seconds
    const pageIndex = Math.min(totalSlides - 1, Math.floor(t / slideDuration));
    const slideStart = pageIndex * slideDuration;

    // Slide transition positioning interpolation
    const transitionDuration = 0.9;
    let translateX;
    if (pageIndex > 0 && t < slideStart + transitionDuration) {
      const p = (t - slideStart) / transitionDuration;
      const easedP = easeBezier(p);
      translateX = -((pageIndex - 1) + easedP) * 100;
    } else {
      translateX = -pageIndex * 100;
    }

    const deck = document.getElementById('deck');
    if (deck) {
      deck.style.transition = 'none';
      deck.style.transform = `translateX(${translateX}vw)`;
    }

    // Trigger page swap only when pageIndex shifts
    if (window.__currentSlideIndex === undefined || window.__currentSlideIndex !== pageIndex) {
      if (document.getAnimations) {
        document.getAnimations().forEach(a => a.cancel());
      }
      window.__currentSlideIndex = pageIndex;
      if (typeof window.lock !== 'undefined') window.lock = false;
      if (typeof go === 'function') go(pageIndex);
    }

    // Precise scrubbing of Web Animations
    const animTimeMs = Math.max(0, (t - (slideStart + 0.45)) * 1000);
    if (document.getAnimations) {
      document.getAnimations().forEach(anim => {
        const effect = anim.effect;
        if (effect && effect.target) {
          const slide = effect.target.closest('.slide');
          if (slide && [...document.querySelectorAll('.slide')].indexOf(slide) === pageIndex) {
            anim.pause();
            anim.currentTime = animTimeMs;
          }
        }
      });
    }
  }

  // Register seek interface and player hijacking hooks
  window.__hf = { duration: 36, seek(t) { transitionToPage(t); } };
  window.__timelines = window.__timelines || {};
  window.__timelines['slide-deck-id'] = {
    getChildren: () => [],
    pause() {},
    play() {},
    seek(t) { transitionToPage(t); }
  };

  function hookPlayer(val) {
    if (val && typeof val.renderSeek === 'function' && !val.__hijacked) {
      val.__hijacked = true;
      const origRenderSeek = val.renderSeek;
      val.renderSeek = function(t) {
        origRenderSeek.call(val, t);
        transitionToPage(t);
      };
    }
  }
  if (window.__player) hookPlayer(window.__player);
  let realPlayer = window.__player;
  Object.defineProperty(window, '__player', {
    configurable: true,
    enumerable: true,
    get() { return realPlayer; },
    set(val) { realPlayer = val; hookPlayer(val); }
  });
})();
</script>
```
