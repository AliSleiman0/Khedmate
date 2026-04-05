# Plan: Grok AI Booking Description Helper

## Overview
Add a "Improve with AI" button to the job_description_screen in the customer Flutter app.
Customer types rough text → taps button → backend calls Grok API → returns polished description →
customer previews and optionally accepts it to fill the field.

## Architecture

### Backend (new endpoint)
- POST /api/ai/improve-description
- Auth: customer JWT (audience: customer)
- Request: { roughDescription, categoryName }
- Response: { success: true, data: { improvedDescription } }
- Service layer: IGrokService / GrokService (IHttpClientFactory)
- Feature flag: Features:AiAssist (toggle off → 501 or passthrough)
- API key: Grok__ApiKey in appsettings, injected from env in docker-compose

### Flutter Customer App
- New ai_repository.dart calls POST /api/ai/improve-description
- job_description_screen.dart: add AI button below description TextField
- When tapped: show loading, then show bottom sheet preview with Accept/Dismiss

## Key files
- backend/src/Khudmati.API/Controllers/AiController.cs (NEW)
- backend/src/Khudmati.API/Services/IGrokService.cs (NEW)
- backend/src/Khudmati.API/Services/GrokService.cs (NEW)
- backend/src/Khudmati.API/Program.cs (register GrokService, read flag)
- backend/src/Khudmati.API/appsettings.json (add Grok + Features sections)
- backend/src/Khudmati.API/appsettings.Development.json (add Grok key placeholder)
- backend/docker-compose.prod.yml (add Grok__ApiKey + Features__AiAssist env vars)
- mobile-customer/lib/features/booking/data/ai_repository.dart (NEW)
- mobile-customer/lib/features/booking/presentation/job_description_screen.dart (add AI button)

## Grok API
- Base URL: https://api.x.ai/v1
- Endpoint: POST /chat/completions (OpenAI-compatible)
- Model: grok-3-mini (cost-effective)
- System prompt: respond in same language, rewrite as clear, professional service request (Arabic/English)
- Input validation: roughDescription max 500 chars
- free tier: $25/month

## Feature flag
- Backend: Features:AiAssist = false by default → endpoint returns 503 or empty passthrough
- Flutter: show AI button only when feature is on (or gracefully handle 503 error)

## Decisions
- API key stored ONLY in env/appsettings (never in code)
- Backend proxies Grok (key never exposed to client)
- Feature flag name: Features:AiAssist (separate from Features:AiScheduling for reminders)
- Model: grok-3-mini
- No rate limiting in V1 (keep simple)
