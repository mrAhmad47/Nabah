# How RouteGuardian Leverages N-ATLaS

## Overview

RouteGuardian integrates **N-ATLaS (Llama 3.2 3B)**, Nigeria's first national open-source multilingual AI model, as the core intelligence engine for real-time travel safety analysis.

---

## Key N-ATLaS Integration Points

### 1. AI-Powered Safety Scoring
N-ATLaS analyzes news headlines and incident reports to generate **safety scores (0-100)** for each travel route. The model evaluates:
- Crime reports (robbery, kidnapping, armed attacks)
- Road incidents (accidents, construction, flooding)
- Security situations (patrols, checkpoints, advisories)

### 2. Intelligent Text Classification
The model **classifies incidents by type and severity** using natural language understanding, identifying keywords and context specific to Nigerian security situations:
- Kidnapping/abduction detection
- Armed robbery recognition
- Accident severity assessment
- Traffic congestion analysis

### 3. Local Inference Architecture
N-ATLaS runs **locally via Python server** using `llama-cpp-python`, providing:
- Real-time AI analysis without cloud dependencies
- Privacy-preserving on-device processing
- Offline capability with demo fallback data

### 4. Route-Specific Safety Analysis
For each route alternative, N-ATLaS:
1. Identifies locations along the route path
2. Searches for recent news (NewsAPI + web scraping)
3. Analyzes headlines for safety indicators
4. Generates a composite safety score and warnings

---

## Technical Implementation

```
Flutter App → HTTP Request → N-ATLaS Python Server
                                    ↓
                            Load GGUF Model
                                    ↓
                            Process with llama-cpp
                                    ↓
                            Return Safety Analysis
```

**Model Used:** `N-ATLaS.Q2_K.gguf` (3GB, quantized for efficiency)

**Server Endpoints:**
- `/analyze` - Text analysis for incident detection
- `/search_news` - Route-based news search with AI analysis
- `/severity` - Incident severity assessment

---

## Impact

RouteGuardian demonstrates how N-ATLaS can be deployed for **public safety applications** in Nigeria, helping travelers make informed decisions about route safety using locally-processed AI intelligence.
