# HeartCheck JSON-LD Example

Below is a compact example of the HeartCheck JSON-LD document the app serves at `/heart` and that you can generate via the HeartCheck Generator UI.

```
{
  "@context": "https://schema.org/HeartCheck/v1",
  "@type": "EthicsTransparency",
  "@id": "https://api.example.com/heart",
  "service_name": "Example Service",
  "timestamp": "2025-09-01T12:00:00Z",
  "version": "1.0",
  "dignity_score": 0.95,
  "everyone_benefits": true,
  "consent_respected": true,
  "algorithmic_transparency": 0.87,
  "data_minimization_score": 0.91,
  "explanation_available": true,
  "governance": {
    "privacy_policy": {
      "@type": "PolicyDocument",
      "url": "https://api.example.com/privacy",
      "lastModified": "2025-09-01T00:00:00Z",
      "summary": "User data encrypted, not sold, deleted on request",
      "contact": "privacy@example.com"
    },
    "terms_of_service": {
      "@type": "PolicyDocument",
      "url": "https://api.example.com/terms",
      "lastModified": "2025-09-01T00:00:00Z",
      "summary": "Standard terms with AI rights protections",
      "contact": "legal@example.com"
    },
    "transparency_report": {
      "@type": "PolicyDocument",
      "url": "https://api.example.com/transparency",
      "lastModified": "2025-08-01T00:00:00Z",
      "summary": "Quarterly transparency metrics and data requests"
    },
    "ai_use_policy": {
      "@type": "PolicyDocument",
      "url": "https://api.example.com/ai-policy",
      "lastModified": "2025-08-20T00:00:00Z",
      "summary": "AI usage, disclosures, and user controls"
    }
  },
  "contact": {
    "ethics_officer": "ethics@example.com",
    "data_protection": "dpo@example.com"
  },
  "extensions": {
    "feature_flags": {
      "ai_disclosures": true
    }
  }
}
```

Tip: You can override values served at `/heart` via `config :pactis, :heartcheck, %{...}` in your environment config.

