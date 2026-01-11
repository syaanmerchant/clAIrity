# clarity
### Turning medical, insurance, and institutional language into plain-English action steps

**clarity** is a Swift-based iOS app that helps people understand what to do **after** a medical or institutional interaction — when confusion is highest and guidance is weakest.

It transforms complex medical, insurance, and administrative language into **clear, structured, and actionable next steps**, without storing any personal data.

---

## 🚑 The Real Problem

People regularly leave:
- Doctor visits
- Emergency room discharges
- Hospital stays
- Specialist consultations
- Insurance decisions
- Accommodation or institutional emails

…with documents they don’t fully understand.

The most broken moment in healthcare isn’t the visit itself — it’s **what happens after you leave**.

---

## 💡 What clarity Does

You select what just happened:
- GP visit
- ER discharge
- Specialist consult
- Insurance or institutional decision

You provide the relevant information, and **clarity** explains:

- **What this actually means**
- **What you need to do**
- **What matters vs. what’s optional**
- **What to ask next**

No accounts.  
No storage.  
Your data stays with you.

---

## 🧠 Core Functionalities

### A. Inputs
The app allows users to:
- Paste medical or institutional text
- Upload a PDF or image
- Take a photo of paperwork
- Select a diagnosis from a list
- Self-report symptoms (optional)
- List current medications (optional)

---

### B. Processing (Internal Logic)

The system:
- Simplifies medical and institutional language
- Extracts medications and dosages
- Extracts tasks and instructions
- Identifies timelines and follow-up requirements
- Flags red-flag symptoms and safety concerns

---



## 🩺 After-Care Logic

clarity supports ongoing care by enabling:

- ✔ Daily recovery plans (Day 1, Day 3, Day 7, etc.)
- ✔ Follow-up triggers  
  *(e.g., “If not improving by day 3, do X”)*  
- ✔ Safety triggers  
  *(e.g., “If fever > X or symptom Y → ER”)*  
- ✔ Reminders for appointments, labs, and follow-ups
- ✔ Self-check prompts  
  *(“Is this normal?”)*

---

## 🧱 Tech Stack & Architecture

clarity is built with a modern, modular stack designed for rapid iteration, reliability, and privacy-conscious processing.

### Frontend
- **Swift**
- **SwiftUI**
- **App Playground–compatible Swift Package**
- Native iOS navigation and state management
- Async/await–based networking

### Core Intelligence (LLM)
- **Large Language Model (Gemini)**  
  Acts as the core reasoning engine to:
  - Read pasted medical, insurance, or institutional text
  - Simplify complex language into plain English
  - Decompose information into structured output cards:
    - What this means
    - What you need to do
    - Medications (what / when / how long)
    - Timeline (today / this week / follow-up)
    - Recovery signs (good vs. red flags)
    - Questions to ask
  - Generate after-care logic:
    - Daily plans (Day 1, Day 3, Day 7, etc.)
    - Conditional follow-up actions
    - Safety triggers (e.g., escalation to urgent care)
    - Self-check prompts and reminders

### Document & Image Processing
- **OCR APIs** (for PDFs and photos of documents):
  - Google Vision API
  - AWS Textract
  - Azure Computer Vision  
  Enables extraction of text from discharge summaries, printed instructions, and scanned paperwork.

### Clinical Language Processing
- **Clinical NLP APIs** for structured medical extraction:
  - Amazon Comprehend Medical
  - Azure Text Analytics for Health
  - Google Healthcare NLP  
  Used to reliably identify:
  - Medications and dosages
  - Diagnoses
  - Clinical instructions and timelines

### Medical Reference Data
- **Public medical references** (e.g., Wikipedia)  
  Used for contextual explanations of conditions, medications, and terminology.

### Privacy & Data Handling
- No user accounts
- No long-term data storage
- Inputs are processed transiently and discarded after use

---

Healthcare doesn’t fail because people don’t care — it fails because instructions are unclear.

**clarity** fixes the gap between *being told* and *knowing what to do*.
