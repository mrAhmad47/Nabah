# RouteGuardian: Project Summary 🛡️

## 📖 Overview
RouteGuardian is an **AI-powered safety routing application** designed specifically for the unique security challenges in Nigeria and Africa. Unlike standard navigation apps that prioritize the *fastest* route, RouteGuardian prioritizes the **safest** route.

It utilizes a custom AI model (**N-ATLaS**) to analyze real-time data from news reports, user submissions, and historical incidents to assign "safety scores" to different routes, helping users avoid high-risk areas prone to kidnapping, banditry, or civil unrest.

## ❓ The Problem
In many regions of Africa, traveling between cities can be risky due to dynamic security threats. Standard GPS apps (Google Maps, Waze) do not account for:
*   Active kidnapping zones.
*   Recent banditry attacks.
*   Flashpoints for civil unrest or protests.
*   Unsafe night-time travel routes.

## 💡 The Solution
RouteGuardian bridges this gap by overlaying a "security layer" on top of standard navigation.

### Key Capabilities:
1.  **AI Risk Assessment (N-ATLaS):**
    *   Uses a localized Large Language Model (Llama 3.2 3B) to read and understand Nigerian news headlines and incident reports.
    *   Scans for keywords like "kidnap", "gunmen", "robbery", and "clash" to determine the severity of a threat.

2.  **Intelligent Route Scoring:**
    *   Provides multiple route alternatives, each with a **Safety Score (0-100)**.
    *   A score of 100 means "Very Safe", while lower scores indicate potential risks.

3.  **Real-Time Data Aggregation:**
    *   **News Discovery:** Automatically scrapes NewsAPI and Google News for the latest security incidents along a route.
    *   **User Reporting:** Allows the community to report incidents (accidents, checkpoints, robberies) in real-time.

4.  **Privacy & Offline First:**
    *   Designed to work with intermittent internet connectivity.
    *   Features a fallback mechanism: if the news API fails, it uses cached data or a demo database to ensure the app never breaks.

## 🛠️ Technology Stack
*   **Frontend:** Flutter (Mobile & Web).
*   **Backend:** Laravel (REST API & FilamentPHP v5 Admin Panel).
*   **AI Service:** Python (hosting the N-ATLaS AI model).
*   **AI Model:** Llama 3.2 3B (Quantized for efficiency).
*   **Data Sources:** Google Directions API, NewsAPI.org, Google News Scraping.

## 🎯 Target Audience
*   Inter-city travelers in Nigeria.
*   Logistics and transport companies.
*   Security-conscious individuals and expatriates.
