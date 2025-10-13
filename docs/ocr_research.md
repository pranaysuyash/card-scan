# OCR & Extraction Options — Local vs Cloud

## Current Stack Checkpoint
- **OCR**: Google ML Kit Text Recognition v2 (`google_mlkit_text_recognition`), already bundles multilingual on-device models for Android/iOS and can dynamically download language packs as needed.[^mlkit]
- **Parsing**: Custom `ParserService` heuristics convert OCR lines into structured `Contact` objects (names, emails, phones, etc.).
- **Storage & UX**: Isar database keeps contacts local; Review → Save flow lets users correct ML output before persistence.

This provides a privacy-friendly baseline, but accuracy for handwriting, dense layouts, and entity normalization still depends on heuristics.

## Local / On-Device Upgrades

| Option | Why it matters | Footprint notes |
| --- | --- | --- |
| **PP-OCRv3 Mobile (PaddleOCR)** | Mobile-tailored detection + recognition pipeline. Reported Chinese end-to-end Hmean 50.3 %, 8.1 MB model, 356 ms CPU latency.[^ppocr] | Ships TensorRT/ONNX/TFLite models; can run via PaddleLite, TFLite, MNN, ncnn. Good candidate for replacing ML Kit when you need deterministic behavior or broader language control. |
| **Tesseract 5** | Mature open-source OCR with UTF-8 support and 100+ languages, includes LSTM engine and training tooling.[^tesseract] | Pure CPU, C++ lib. Heavier to tune but transparent; good for on-device Linux/macOS builds (desktop export), less ideal on mobile without wrappers. |
| **docTR (Mindee)** | Two-stage detection/recognition with PyTorch/TensorFlow backends, extensive pretrained models.[^doctr] | Optimized for server/desktop. Could serve as base for your own edge engine after exporting to TFLite/ONNX and quantizing. |
| **TrOCR (Microsoft)** | Transformer encoder-decoder for single-line OCR with SOTA accuracy on printed text.[^trocr] | Base model is large (222 M params). Needs GPU or aggressive quantization; fits best in a server or powerful device. |
| **Qwen2-VL (2B / 7B)** | Multimodal LLM that scores highly on DocVQA and OCRBench (2B hits 90.1 on DocVQA test).[^qwen2b][^qwen7b] | Even the 2B model is heavy (~4 GB FP16). Requires GPU/Metal with frameworks like llama.cpp/MLC LLM for on-device inference. Offers image understanding + reasoning beyond OCR. |
| **llama.cpp + GGUF** | C/C++ runtime supporting many LLMs with 1.5–8-bit quantization and hybrid CPU/GPU execution.[^llama] | Path to run quantized Qwen2-VL, MiniCPM-V, etc. on desktops and high-end phones (Metal/Vulkan). |
| **MLC LLM** | Compiler toolchain that deploys LLMs (including multimodal) natively to iOS, Android, WebGPU with unified runtime.[^mlcllm] | Helpful if you pursue transformer-based extraction in-app; integrates with quantized weights and offers REST/JS bindings. |

### Practical local roadmap
1. **Short term**: stay with ML Kit but add better parsing confidence + fallback editing cues.
2. **Medium term**: prototype PP-OCRv3 mobile model via PaddleLite/TFLite; compare latency/accuracy vs ML Kit.
3. **Advanced**: explore docTR/TrOCR exports for server-assisted or high-end device modes.
4. **Vision-Language**: when you need layout-aware reasoning (e.g., extracting titles vs subtitles), evaluate quantized Qwen2-VL 2B inside llama.cpp or MLC LLM. Expect significant engineering effort (GPU/Metal, memory budgeting, batching).

## Cloud / API Services

| Provider | Highlights | Monetization fit |
| --- | --- | --- |
| **Google Cloud Vision OCR** | Offers `TEXT_DETECTION` and `DOCUMENT_TEXT_DETECTION`, returns structured bounding boxes; Google notes Firebase ML/ML Kit for mobile on-device complement.[^gcv] | Pay-as-you-go; bundle into a “pro” tier with higher accuracy or batch ingestion. |
| **Amazon Textract** | Detects printed & handwritten text, tables, forms; includes Queries, AnalyzeExpense, AnalyzeID workflows.[^textract] | Tiered pricing, powerful for enterprise customers needing structured outputs. |
| **Azure Document Intelligence / Read OCR** | Cloud or container-based, supports global languages, integrates with broader IDP capabilities.[^azure] | Good for customers already in Microsoft ecosystem; container option allows VPC deployment. |
| **Mindee API** | (Not yet integrated) Offers API products for receipts, invoices, business cards; pairs well with docTR tooling. | Could power premium “auto-fill” features; pricing is usage-based. |

### API paywall strategy
1. **Baseline (free tier)**: on-device ML Kit + heuristics, limited to manual review.
2. **Pro tier**: route scans through a chosen cloud OCR/Document AI service for higher accuracy, multi-page batch processing, entity extraction (addresses, titles). Offer monthly subscription covering API costs plus margin.
3. **Enterprise tier**: add CRM push (HubSpot/Salesforce), SSO, export automation; possibly meter per-document beyond plan.

## Research Takeaways & Next Steps
1. **Benchmark reality**: Capture a representative corpus of business cards (print, handwriting, multilingual). Run ML Kit vs PP-OCRv3 vs chosen API; track precision/recall for core fields.
2. **Quantization experiments**: If you pursue Qwen2-VL/TrOCR, prototype with llama.cpp or MLC LLM on Apple Silicon first, then profile on Android (Adreno) via Vulkan.
3. **Hybrid architecture**: Design a toggle letting users opt into “private (device)” vs “premium (cloud)” processing; store API key server-side to avoid leaks.
4. **Pricing model**: Start with a $7–$10/mo pro plan (includes X documents using Vision/Textract) and overage per batch. Validate with beta testers.
5. **Compliance**: If you move data to cloud APIs, add consent screens, encryption-in-transit, and allow users to purge uploads.

---

[^mlkit]: Google, “Recognize text in images with ML Kit on Android,” ML Kit docs (accessed Oct 2024).  
[^ppocr]: PaddlePaddle, “PP-OCRv3 Introduction,” mobile model metrics (Hmean 50.30 %, size 8.1 MB, CPU 356 ms) (release/2.7).  
[^tesseract]: Tesseract OCR README (main branch), notes on LSTM engine, UTF-8 support, >100 languages.  
[^doctr]: Mindee `docTR` README, describing two-stage detection + recognition pipeline.  
[^trocr]: Microsoft “TrOCR: Transformer-based OCR,” Hugging Face model card for `microsoft/trocr-base-printed`.  
[^qwen2b]: Qwen team, Qwen2-VL-2B-Instruct README (DocVQA test 90.1, OCRBench 794).  
[^qwen7b]: Qwen team, Qwen2-VL-7B-Instruct README (DocVQA test 94.5, TextVQA 84.3, notes on 2/7/72B variants).  
[^llama]: `llama.cpp` README, goal of enabling LLM inference across hardware with low-bit quantization.  
[^mlcllm]: MLC LLM homepage outlining native deployment engine across iOS/Android/WebGPU.  
[^gcv]: Google Cloud Vision OCR docs — highlights TEXT_DETECTION vs DOCUMENT_TEXT_DETECTION and suggests ML Kit for on-device use.  
[^textract]: AWS Textract docs summarizing features (handwritten text, tables, forms, queries, ID, lending).  
[^azure]: Microsoft Azure AI Vision OCR overview describing Read OCR engine, multilingual support, and container deployment.
