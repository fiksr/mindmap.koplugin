# 🕸️ MindMap for KOReader

[![KOReader](https://img.shields.io/badge/KOReader-2024%2B-blue.svg)](https://github.com/koreader/koreader)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![AI Powered](https://img.shields.io/badge/AI%20Relations-Groq%20%7C%20Gemini-purple.svg)]()
[![Storefront Compatible](https://img.shields.io/badge/Storefront-Compatible-purple.svg)](https://omer-faruq.github.io/koreader-plugin-index/)

**MindMap** is an AI-powered **Character Relationship Web & Plot Timeline companion** for KOReader on Kindle and Kobo e-readers.

Designed specifically for complex epic fantasy, mystery, sci-fi, and historical fiction novels (such as *Dune*, *A Song of Ice and Fire*, *The Wheel of Time*, *War and Peace*, *Malazan*, or Agatha Christie mysteries) where dozens of characters, shifting alliances, and rival houses make tracking the narrative difficult.

---

## ✨ Features

- 🕸️ **Character Relationship Dossiers**:
  - Highlights alliances, rivalries, family ties, mentors, and lovers in a clean E-Ink Unicode tree.
  - Summarizes current character role and status strictly bounded by your reading progress.
- 🛡️ **Zero-Spoiler Guarantee**:
  - The AI prompt engine strictly constrains character relations and timeline events **up to your exact chapter/page**.
  - Never reveals future betrayals, secret identities, or upcoming plot twists.
- 🏰 **Faction & Houses Web**:
  - View high-level power structures, factions, guilds, and houses overview with key leaders and retainers.
- ⏳ **Chronological Plot Milestone Timeline**:
  - Recaps major story milestones leading up to your current point in the book.
- 👆 **One-Tap Highlight Action**:
  - Highlight any name in your book ➔ tap **🕸️ MindMap: Relations** for an instant dossier.
- ⚡ **Blazing Fast & Free AI Engines**:
  - Powered by **Groq** (`openai/gpt-oss-120b`, `qwen/qwen3.8-27b`) or **Google Gemini** (`gemini-3.5-flash-lite`).
  - Supports OpenAI, DeepSeek, and 100% offline local **Ollama** via LAN.
- 💾 **Instant Offline Caching**:
  - Once generated, character webs and timelines are stored locally on your device for instant offline recall.
- 🌐 **Bilingual Support**:
  - Switch seamlessly between **English** and **Serbian (Srpski - Latin)**.

---

## 🚀 Installation

### Via Storefront / AppStore
1. In KOReader, go to **Tools** ➔ **App Store** (or **Storefront**).
2. Search for **MindMap** and tap **Install**.
3. Restart KOReader.

### Manual Installation
1. Download `mindmap.koplugin.zip` from [Releases](https://github.com/fiksr/mindmap.koplugin/releases).
2. Extract the folder to:
   - **Kindle**: `/mnt/us/koreader/plugins/mindmap.koplugin/`
   - **Kobo**: `.kobo/koreader/plugins/mindmap.koplugin/`
3. Restart KOReader.

---

## 🔑 Quick API Key Setup

You can place your free Groq or Gemini API key in a text file on your Kindle's USB storage root:
- `/mnt/us/groq_key.txt` (or `/mnt/us/gemini_key.txt`)

Then open **Tools ➔ More tools ➔ MindMap ➔ 📥 Import API Keys from Kindle Storage**. MindMap will automatically import and configure your key!

---

## 📄 License

MIT License. Designed with love for the KOReader e-ink reading community.
