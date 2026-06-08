---
name: pdf-reader
description: "Read, parse, and extract text, tables, and metadata from PDF files. Support structured Markdown output, tabular rendering, and document summarization. DO NOT invoke for editing PDF files, converting PDF to other formats, handling non-PDF document parsing tasks, or general file system operations that do not require inspecting the internal contents of PDF documents."
allowed-tools: Read
version: 1.0.0
---

# PDF Reader

Read and parse PDF document contents, extracting text, tables, and metadata.

## When to invoke
- When the user asks to read, analyze, or extract content from a PDF file.
- When performing document processing tasks involving PDF data extraction.
- **DO NOT invoke when**: You need to edit, modify, encrypt, or convert PDF files, or when dealing with formats other than PDF.

## 📦 Prerequisites & Context
- Node.js or Python runtime environment installed.
- Appropriate PDF extraction tool/library (e.g., `pdfplumber`, `pdf-parse`) available.

## 🛠 Toolchain
| Tool | Purpose | Constraint |
| --- | --- | --- |
| `pdf-parse` / `pdfplumber` | Text and table extraction | Must be installed or executed dynamically via standard runtime |

## 📋 Execution Workflow

### Phase 1: Extract Text & Metadata
1. Locate the target PDF file path.
2. Load the PDF file using the appropriate library (e.g., python `pdfplumber` or node `pdf-parse`).
3. Extract raw text page by page, preserving spacing and structural hierarchy.
4. Extract document metadata (title, author, creation date, page count).
- ✅ Success: PDF content and metadata are successfully read and loaded.
- 🔄 Fallback: If the PDF is encrypted, prompt the user for the password; if it is scanned, request OCR processing capability.

### Phase 2: Format & Present Content
1. Convert extracted text into clean Markdown formatting.
2. Render any extracted tabular data into Markdown tables.
3. Organize the metadata into a clear key-value list.
- ✅ Success: Extracted data is formatted and presented clearly to the user.
- 🔄 Fallback: If formatting is messy due to multi-column layouts, present the raw text blocks sequentially.

## ⚠️ Rules & Guardrails
- **MUST**: Always confirm the PDF path is correct before attempting to open it.
- **MUST NOT**: Attempt to write to or modify the source PDF file.
- **SHOULD**: Process large PDF files page-by-page or in chunks to prevent memory issues.
