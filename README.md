<div align="center">
  <img src="https://github.com/user-attachments/assets/fe5087aa-407a-41b7-871b-98b0c02a7ac9" width="150" alt="Holocron App Icon"/>

# Holocron for macOS

**Summon the wisdom of any AI model, from anywhere on your Mac, with a single hotkey.**

<p>
  <img alt="macOS" src="https://img.shields.io/badge/macOS-15.0%2B-blue?style=for-the-badge&logo=apple"/>
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge&logo=swift"/>
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge"/>
  <img alt="Version" src="https://img.shields.io/badge/Version-0.1.0-purple?style=for-the-badge"/>
</p>
</div>

<div align="center">
  <img src="https://github.com/user-attachments/assets/846f17fe-9b77-4ec0-9610-8215af8e3122" alt="Holocron Demo GIF" />
</div>

---

Holocron is a native macOS app built for speed and simplicity. It eliminates the need to open a browser tab for every quick question. It's your personal, always-on AI gateway, designed to integrate seamlessly into your workflow without ever getting in the way.

## Key Features

* **✨ Instant Access:** Summon Holocron with a global hotkey (**`⌥ + ⌘ + Space`**) without leaving your current app.
* **🔮 Universal AI Support:** Connect to OpenAI, Gemini, Anthropic, and Grok, with more providers planned.
* **🛰️ Menu Bar Native:** Lives discreetly in your menu bar. No Dock icon, no clutter—just pure utility.
* **📜 Persistent Conversations:** Your chat history is saved locally, letting you pick up where you left off.
* **⚡ Blazing Fast:** Built natively with SwiftUI for a lightweight and responsive experience.

## Requirements

* macOS 15.0+ (Sequoia)
* Xcode 17.0+
* Swift 5.10+

## Installation & Usage (From Source)

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/0xr3ngar/holocron.git
    cd holocron
    ```
2.  **Open in Xcode and Run:**
    ```sh
    xed .
    ```
    Press **`Cmd+R`** to build and run. The app will ask for Accessibility permissions to enable the global hotkey.


## Roadmap

This project is actively growing. Here's what's planned:
- [x] Vibe out a first version :trollface:
- [ ] Rewrite from scratch and don't use AI
- [ ] Multi-provider support (OpenAI, Gemini, Anthropic, Grok)
- [ ] Official v1.0.0 Release with `.dmg` installer
- [ ] Publish brew package
- [ ] Customizable hotkeys
- [ ] Streaming responses for real-time answers
- [ ] Custom theme options (Light/Dark/System/Custom)
- [ ] Share conversation snippets as images or markdown

## The Origin Story

Holocron began as a one-afternoon experiment, born from a simple question: **"Just how good is the new Claude Sonnet 4.5 model?"** 

The initial "vibed-out" version (in the `chore/vibed-first-version` branch) was the answer—a super fast proof-of-concept. 

The `master` branch is now a going to be a complete rewrite focused on building a polished application, that was actually written by a human lol. 

This project is my journey into learning Swift, so all feedback is highly encouraged!

Got an idea or found a bug? Please [**open an issue**](https://github.com/0xr3ngar/holocron/issues).
