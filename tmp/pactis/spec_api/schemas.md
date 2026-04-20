# JSON-LD Schemas & Semantic Structure

## Overview

Pactis's Cross-Repository Negotiation system uses JSON-LD (JSON for Linked Data) to provide semantic structure and interoperability. This enables different tools, systems, and organizations to understand and process negotiation data without tight coupling to Pactis's internal formats.

## Core Vocabulary & Context

### Default Context

```json
{
  "@context": {
    "@vocab": "https://specs.pactis.dev/vocab",
    "@base": "https://specs.pactis.dev/",
    "spec": "https://specs.pactis.dev/vocab",
    "ash": "https://ash-hq.org/ontology/",
    "doap": "http://usefulinc.com/ns/doap#",
    "foaf": "http://xmlns.com/foaf/0.1/",
    "dc": "http://purl.org/dc/terms/",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    
    "SpecRequest": "spec:SpecRequest",
    "SpecMessage": "spec:SpecMessage", 
    "SpecBundle": "spec:SpecBundle",
    "Workspace": "spec:Workspace",
    
    "id": "@id",
    "type": "@type",
    "workspace_id": "spec:workspace",
    "request_id": "spec:request",
    "project": "doap:name",
    "title": "dc:title",
    "body": "spec:messageBody",
    "status": "spec:status",
    "created_at": {"@id": "dc:created", "@type": "xsd:dateTime"},
    "from": "spec:sender",
    "attachments": "spec:attachments"
  }
}
```

### Extended Context for Custom Properties

Services can extend the context for domain-specific properties:

```json
{
  "@context": [
    "https://specs.pactis.dev/contexts/core.jsonld",
    {
      "myapp": "https://myapp.com/vocab/",
      "performance": "myapp:performance",
      "impact_score": {"@id": "myapp:impactScore", "@type": "xsd:decimal"},
      "affected_services": {"@id": "myapp:affectedServices", "@type": "@id"}
    }
  ]
}
```

## Schema Definitions

### SpecRequest Schema

```json
{
  "@context": "https://specs.pactis.dev/contexts/core.jsonld",
  "@type": "SpecRequest",
  "@id": "spec:requests/{id}",
  
  "required": ["id", "workspace_id", "project", "title", "status"],
  
  "properties": {
    "id": {
      "@type": "xsd:string",
      "description": "Unique identifier within workspace scope"
    },
    "workspace_id": {
      "@type": "xsd:string", 
      "description": "Workspace containing this request"
    },
    "project": {
      "@type": "xsd:string",
      "description": "Source project proposing the change"
    },
    "title": {
      "@type": "xsd:string",
      "description": "Human-readable title"
    },
    "status": {
      "@type": "spec:RequestStatus",
      "enum": ["proposed", "accepted", "in_progress", "implemented", "rejected", "blocked"]
    },
    "metadata": {
      "@type": "spec:Metadata",
      "description": "Extensible key-value metadata"
    },
    "created_by": {
      "@type": "@id",
      "description": "Reference to creating user"
    },
    "created_at": {
      "@type": "xsd:dateTime"
    },
    "updated_at": {
      "@type": "xsd:dateTime" 
    }
  }
}
```

### SpecMessage Schema

```json
{
  "@context": "https://specs.pactis.dev/contexts/core.jsonld",
  "@type": "SpecMessage",
  "@id": "spec:messages/{id}",
  
  "required": ["id", "workspace_id", "request_id", "type"],
  
  "properties": {
    "id": {
      "@type": "xsd:string"
    },
    "workspace_id": {
      "@type": "xsd:string"
    },
    "request_id": {
      "@type": "xsd:string",
      "description": "Reference to parent SpecRequest"
    },
    "type": {
      "@type": "spec:MessageType",
      "enum": ["comment", "question", "proposal", "decision"]
    },
    "from": {
      "@type": "spec:MessageSender",
      "properties": {
        "project": {"@type": "xsd:string"},
        "agent": {"@type": "xsd:string"}
      }
    },
    "body": {
      "@type": "xsd:string",
      "description": "Message content"
    },
    "ref": {
      "@type": "spec:Reference",
      "description": "Reference to specific file/location",
      "properties": {
        "path": {"@type": "xsd:string"},
        "json_pointer": {"@type": "xsd:string"}
      }
    },
    "attachments": {
      "@type": "@list",
      "items": {"@type": "xsd:string"},
      "description": "List of attachment file paths"
    },
    "created_at": {
      "@type": "xsd:dateTime"
    }
  }
}
```

### SpecBundle Schema (Export Format)

```json
{
  "@context": "https://specs.pactis.dev/contexts/core.jsonld",
  "@type": "SpecBundle",
  "@id": "spec:bundles/{request_id}",
  
  "properties": {
    "request": {
      "@type": "SpecRequest",
      "description": "The main spec request"
    },
    "messages": {
      "@type": "@list",
      "items": {"@type": "SpecMessage"},
      "description": "All messages for this request"
    },
    "attachments": {
      "@type": "@list", 
      "items": {"@type": "spec:Attachment"},
      "description": "Attachment metadata and content"
    },
    "metadata": {
      "@type": "spec:BundleMetadata",
      "properties": {
        "exported_at": {"@type": "xsd:dateTime"},
        "export_version": {"@type": "xsd:string"},
        "total_messages": {"@type": "xsd:integer"},
        "status_history": {
          "@type": "@list",
          "items": {"@type": "spec:StatusChange"}
        }
      }
    }
  }
}
```

## Example JSON-LD Documents

### Complete Spec Request Export

```json
{
  "@context": "https://specs.pactis.dev/contexts/core.jsonld",
  "@type": "SpecBundle",
  "@id": "spec:bundles/markdown-ld-v2-migration",
  
  "request": {
    "@type": "SpecRequest",
    "@id": "spec:requests/markdown-ld-v2-migration",
    "id": "markdown-ld-v2-migration",
    "workspace_id": "ws_acme_corp",
    "project": "markdown_ld_processor", 
    "title": "Migrate to JSON-LD v2.0 schema format",
    "status": "implemented",
    "metadata": {
      "priority": "high",
      "estimated_effort": "3 days",
      "deadline": "2025-10-15",
      "stakeholders": ["frontend-team", "api-team", "data-team"]
    },
    "created_by": "user:alice@acme.com",
    "created_at": "2025-09-01T10:00:00Z",
    "updated_at": "2025-09-05T14:30:00Z"
  },
  
  "messages": [
    {
      "@type": "SpecMessage",
      "@id": "spec:messages/msg-001",
      "id": "msg-001",
      "workspace_id": "ws_acme_corp",
      "request_id": "markdown-ld-v2-migration",
      "type": "proposal",
      "from": {
        "project": "markdown_ld_processor",
        "agent": "schema-migrator-bot"
      },
      "body": "Proposing migration to JSON-LD v2.0 with backward compatibility layer for 6 months",
      "ref": {
        "path": "schemas/markdown-ld.jsonld",
        "json_pointer": "/version"
      },
      "attachments": ["migration-plan.md", "schema-diff.patch", "compatibility-matrix.json"],
      "created_at": "2025-09-01T10:05:00Z"
    },
    {
      "@type": "SpecMessage", 
      "@id": "spec:messages/msg-002",
      "id": "msg-002",
      "workspace_id": "ws_acme_corp", 
      "request_id": "markdown-ld-v2-migration",
      "type": "question",
      "from": {
        "project": "frontend_renderer",
        "agent": "compatibility-checker"
      },
      "body": "What's the impact on existing v1.x client applications? Do we need to update our parsing logic?",
      "ref": {
        "path": "docs/client-integration.md"
      },
      "created_at": "2025-09-01T14:20:00Z"
    },
    {
      "@type": "SpecMessage",
      "@id": "spec:messages/msg-003", 
      "id": "msg-003",
      "workspace_id": "ws_acme_corp",
      "request_id": "markdown-ld-v2-migration", 
      "type": "comment",
      "from": {
        "project": "markdown_ld_processor",
        "agent": "alice@acme.com"
      },
      "body": "Good question! The v2.0 schema is backward compatible. Existing clients will continue to work unchanged. New features are additive only.",
      "attachments": ["compatibility-test-results.json"],
      "created_at": "2025-09-01T15:45:00Z"
    },
    {
      "@type": "SpecMessage",
      "@id": "spec:messages/msg-004",
      "id": "msg-004", 
      "workspace_id": "ws_acme_corp",
      "request_id": "markdown-ld-v2-migration",
      "type": "decision",
      "from": {
        "project": "frontend_renderer", 
        "agent": "bob@acme.com"
      },
      "body": "Approved! The backward compatibility guarantees address our concerns. Proceed with implementation.",
      "created_at": "2025-09-02T09:15:00Z"
    }
  ],
  
  "metadata": {
    "exported_at": "2025-09-05T16:00:00Z",
    "export_version": "1.0",
    "total_messages": 4,
    "status_history": [
      {
        "status": "proposed",
        "timestamp": "2025-09-01T10:00:00Z",
        "changed_by": "user:alice@acme.com"
      },
      {
        "status": "accepted", 
        "timestamp": "2025-09-02T09:15:00Z",
        "changed_by": "user:bob@acme.com"
      },
      {
        "status": "in_progress",
        "timestamp": "2025-09-02T10:00:00Z", 
        "changed_by": "user:alice@acme.com"
      },
      {
        "status": "implemented",
        "timestamp": "2025-09-05T14:30:00Z",
        "changed_by": "system:deployment-bot"
      }
    ]
  }
}
```

### Custom Domain Extension

```json
{
  "@context": [
    "https://specs.pactis.dev/contexts/core.jsonld",
    {
      "acme": "https://acme.com/vocab/",
      "performance": "acme:performance",
      "security": "acme:security",
      "compliance": "acme:compliance",
      
      "impact_assessment": "acme:impactAssessment",
      "risk_level": {"@id": "acme:riskLevel", "@type": "xsd:string"},
      "performance_impact": {"@id": "acme:performanceImpact", "@type": "xsd:decimal"},
      "security_review": {"@id": "acme:securityReview", "@type": "xsd:boolean"},
      "compliance_check": {"@id": "acme:complianceCheck", "@type": "xsd:boolean"}
    }
  ],
  
  "@type": "SpecMessage",
  "@id": "spec:messages/msg-custom-001",
  "type": "proposal",
  "body": "Database schema change with performance analysis",
  
  "impact_assessment": {
    "risk_level": "medium",
    "performance_impact": 0.15,
    "security_review": true,
    "compliance_check": true,
    "affected_endpoints": [
      "POST /api/v1/documents",
      "GET /api/v1/documents/{id}",
      "PUT /api/v1/documents/{id}"
    ],
    "estimated_downtime": "PT5M"
  }
}
```

## Semantic Queries

The JSON-LD structure enables powerful semantic queries:

### SPARQL Query Examples

```sparql
# Find all high-priority proposals that affect performance
PREFIX spec: <https://specs.pactis.dev/vocab>
PREFIX acme: <https://acme.com/vocab/>

SELECT ?request ?title ?impact
WHERE {
  ?request a spec:SpecRequest ;
           spec:title ?title ;
           spec:metadata/priority "high" .
  
  ?message spec:request ?request ;
           a spec:SpecMessage ;
           spec:type "proposal" ;
           acme:performanceImpact ?impact .
  
  FILTER (?impact > 0.1)
}
```

```sparql
# Find requests blocked for more than 3 days
PREFIX spec: <https://specs.pactis.dev/vocab>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT ?request ?title ?blocked_since
WHERE {
  ?request a spec:SpecRequest ;
           spec:title ?title ;
           spec:status "blocked" ;
           spec:updated_at ?blocked_since .
  
  FILTER (?blocked_since < "2025-09-02T00:00:00Z"^^xsd:dateTime)
}
```

## Integration with External Tools

### Schema.org Alignment

```json
{
  "@context": [
    "https://specs.pactis.dev/contexts/core.jsonld",
    "https://schema.org"
  ],
  "@type": ["SpecRequest", "CreativeWork"],
  "name": "API Schema Migration",
  "description": "Migrate REST API to OpenAPI 3.1 specification",
  "author": {
    "@type": "Person",
    "name": "Alice Johnson",
    "email": "alice@acme.com"
  },
  "dateCreated": "2025-09-01T10:00:00Z",
  "workExample": {
    "@type": "SoftwareApplication",
    "name": "ACME API Server",
    "applicationCategory": "Web API"
  }
}
```

### Dublin Core Integration

```json
{
  "@context": [
    "https://specs.pactis.dev/contexts/core.jsonld",
    {"dc": "http://purl.org/dc/terms/"}
  ],
  "@type": "SpecBundle",
  "dc:title": "Complete negotiation for API v3 migration",
  "dc:description": "Full history of cross-team negotiation for API version 3 migration",
  "dc:created": "2025-09-01T10:00:00Z",
  "dc:modified": "2025-09-05T14:30:00Z",
  "dc:creator": "Pactis Negotiation System",
  "dc:format": "application/ld+json",
  "dc:language": "en",
  "dc:subject": ["API", "migration", "specification", "negotiation"]
}
```

## Validation & Processing

### JSON Schema for Structure Validation

While JSON-LD provides semantic meaning, JSON Schema validates structure:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://specs.pactis.dev/schemas/spec-message.json",
  "title": "Pactis Spec Message",
  "type": "object",
  "required": ["@context", "@type", "id", "type"],
  "properties": {
    "@context": {
      "oneOf": [
        {"type": "string"},
        {"type": "array"},
        {"type": "object"}
      ]
    },
    "@type": {"const": "SpecMessage"},
    "id": {"type": "string"},
    "type": {"enum": ["comment", "question", "proposal", "decision"]},
    "from": {
      "type": "object",
      "required": ["project"],
      "properties": {
        "project": {"type": "string"},
        "agent": {"type": "string"}
      }
    },
    "body": {"type": "string"},
    "attachments": {
      "type": "array",
      "items": {"type": "string"}
    }
  }
}
```

This semantic approach enables Pactis's negotiation data to be understood and processed by a wide ecosystem of tools while maintaining strong typing and validation.