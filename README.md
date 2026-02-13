# 📝 Memopa
> **Momentary Delight Over Complexity** — A minimalist memo app focusing on tactile feedback and seamless text interaction.

---

## 🛠 Tech Stack

| Technology | Role |
| :--- | :--- |
| **SwiftUI** | Modern, declarative UI construction |
| **SwiftData** | Fast, intuitive persistence framework |
| **UIKit Integration** | Advanced text control via `UIViewRepresentable` |
| **Observation** | State management with the latest `@Observable` macro |
| **Gemini API** | AI-powered text explanation and analysis |

---

## 🌟 Key Features

* **✨ Magic Copy Experience**
    * Automatic "Copy-on-Select" functionality.
    * Smart **0.7s debounce** to prevent accidental triggers.
* **🫨 Haptic Feedback**
    * Subtle vibrations on successful copy to enhance the "tactile" feel.
* **🫧 Glassmorphic HUD**
    * Beautifully translucent "Copied!" badge for visual confirmation.
* **💾 Robust Auto-save**
    * Instant data persistence ensures your thoughts are never lost.
* **🤖 AI-Powered Explanations**
    * Customizable AI buttons on keyboard toolbar
    * Multi-card response format for easy information scanning
    * Swipe gestures to adopt or discard AI suggestions
* **📋 Smart Clipboard Integration**
    * Long-press to paste from clipboard
    * Automatic clipboard suggestion on new notes

---

## 🏗 Architecture

### MVVM Pattern
* **Models**: `Note`, `EditorElement`, `AIButtonConfig`, `AIResponseCard`
* **ViewModels**: `NoteViewModel`, `NoteListViewModel`, `SettingsViewModel`, `AIButtonConfigViewModel`
* **Views**: `NoteDetailView`, `NoteListView`, `SettingsView`, `AIButtonConfigView`
* **Services**: `GeminiAPIService`, `KeychainService`

### AI Response Format
AI responses are structured as JSON with multiple cards for better information organization:

```json
{
  "card_count": 3,
  "cards": [
    {
      "title": "見出し",
      "body": "説明文（箇条書きは「・」を使用）"
    }
  ]
}
```

---

## 🚀 Philosophy

> **"Tactile experience over feature bloating."**

By bridging the gap between SwiftUI and UIKit, Memopa achieves a level of interaction density that standard components can't reach. Every millisecond of delay and every vibration is tuned to make writing feel **effortless and magical**.

---

## 📸 Screenshots
> --
