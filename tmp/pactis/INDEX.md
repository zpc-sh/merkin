# Pactis Documentation Index

This directory contains comprehensive documentation for Pactis (Conversation-Driven Framework Manager).

## 📖 Core Documentation

- [API Specification](ApiSpec.md) - The full API specification
 - [System Diagrams](DIAGRAMS.md) - High-level mermaid diagrams

### Getting Started
- [Getting Started Guide](getting_started.md) - Step-by-step setup and first steps
- [Architecture Overview](architecture.md) - System architecture and design principles

### Implementation Status
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - Technical implementation overview
- [Implementation Status](implementation_status.md) - Current development progress
 - [Avici Integration Guide](AVICI_INTEGRATION_GUIDE.md) - Code changes, APIs, resources, and next steps

## 🏗 System Architecture

### Phase Development
- [Phase 1: Repository Basics](phase1_repository_basics_spec.md) - Git hosting and basic repository management
- [Phase 2: Conversation Integration](phase2_conversation_integration_spec.md) - Conversation-driven development workflows

### Core Systems
- [Ash Framework Integration](ash.md) - Domain modeling and resource management
- [Blueprints System](blueprints.md) - Component and template system

### Pactis (Standards & BCP)
- [Pactis Framework — RFC](specifications/Pactis.md) - Canonical JSON‑LD shapes, context policy, validation, determinism, conformance
- [Managed Pactis Operations (MPO) — BCP](specifications/MPO_BCP.md) - Operational practice (queues, retries/backoff, DLQ, events, governance)
- Profiles under Pactis:
  - [Pactis‑TVI: Truth Validation Interface](specifications/Pactis-TVI.md)
  - [Pactis‑GRI: Generator Registry Interface](specifications/Pactis-GRI.md)
 - [Pactis‑API: Artifact Publication Interface](specifications/Pactis-API.md)
  - [Pactis‑VFS: Artifact File Serving Profile](specifications/Pactis-VFS.md)
 - Interfaces:
  - [Pactis‑DAI: Design API Interface](specifications/Pactis-DAI.md)
  - [Pactis‑SRI: Service Registry Interface](specifications/Pactis-SRI.md)
   - [Pactis‑CFP: Context Frame Protocol](specifications/Pactis-CFP.md)
   - [Pactis‑KEI: Knowledge Engine Interface](specifications/Pactis-KEI.md)
   - [Pactis‑SMI: Settlement & Metering Interface](specifications/Pactis-SMI.md)
   - [Pactis‑CAI: Content Authoring Interface](specifications/Pactis-CAI.md)
   - [Pactis‑TAI: Test API Interface](specifications/Pactis-TAI.md)
   - [Pactis‑LGI: Logs & Telemetry Interface](specifications/Pactis-LGI.md)
   - [Tokens Best Practices](design/TOKENS_BEST_PRACTICES.md)
  - [Cookbook: New Service Workflow](design/COOKBOOK_NEW_SERVICE.md)
  - [Service Manifest Guide](SERVICE_MANIFEST_GUIDE.md)
 - Trademark & Naming:
   - [Pactis Trademark & Naming Policy](specifications/Pactis_Trademark_and_Naming_Policy.md)
   - [Trademark Knockout Search Checklist](specifications/Trademark_Knockout_Checklist.md)

## 🗨️ Conversation API

### Spec API Documentation
- [Spec API Overview](spec_api/README.md) - Main entry point for conversation API
- [Protocol Specification](spec_api/protocol.md) - Message formats and conversation protocols
- [Implementation Guide](spec_api/implementation.md) - How to integrate with the Spec API
- [API Examples](spec_api/examples.md) - Practical usage examples
- [Schema Reference](spec_api/schemas.md) - Data structure definitions
- [API Overview](spec_api/overview.md) - High-level API concepts
 - [Method Spec Registry](spec_api/method_registry.md) - JSON‑LD method specs, schemas, OpenAPI

## 🔧 Technical Components

### File System & Storage
- [Memory API (Mem)](mem.md) - Content-addressable storage system
- [Database Objects (DOB)](dob.md) - Database and data management
- [File Formats (FF)](ff.md) - File format specifications

### Development Tools
- [Agent System](agent.md) - AI agent integration and management
- [Single File Components](single.md) - Single-file component development

## 📁 Documentation Organization

### By Audience

**🧑‍💻 Developers**
- Start with [Getting Started](getting_started.md)
- Read [Architecture](architecture.md) for system overview
- Explore [Spec API](spec_api/README.md) for integration

**🏗️ System Architects** 
- Review [Architecture](architecture.md)
- Study [Phase 1](phase1_repository_basics_spec.md) and [Phase 2](phase2_conversation_integration_spec.md) specs
- Examine [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

**🎨 Component Developers**
- Focus on [Blueprints System](blueprints.md)
- Check [Getting Started](getting_started.md) for setup
- Use [API Examples](spec_api/examples.md) for integration

**🔬 API Integrators**
- Begin with [Spec API Overview](spec_api/README.md)
- Study [Protocol Specification](spec_api/protocol.md)
- Follow [Implementation Guide](spec_api/implementation.md)

### By Feature

**Repository Management**
- [Phase 1 Spec](phase1_repository_basics_spec.md) - Git hosting
- [Memory API](mem.md) - Content storage
- [Architecture](architecture.md) - System design

**Conversation System**
- [Phase 2 Spec](phase2_conversation_integration_spec.md) - Conversation integration
- [Spec API docs](spec_api/) - Complete API reference
- [Agent System](agent.md) - AI integration

**Component Platform**
- [Blueprints](blueprints.md) - Component system
- [Single File Components](single.md) - Development approach
- [Getting Started](getting_started.md) - Setup and usage

## 🔍 Finding Information

### Quick Reference
| Looking for... | Check... |
|---|---|
| How to set up Pactis | [Getting Started](getting_started.md) |
| API integration | [Spec API](spec_api/README.md) |
| System architecture | [Architecture](architecture.md) |
| Current features | [Implementation Status](implementation_status.md) |
| Component development | [Blueprints](blueprints.md) |
| Database schemas | [Schema Reference](spec_api/schemas.md) |

### Status Indicators
- ✅ **Complete** - Fully documented and implemented
- 🚧 **In Progress** - Documentation exists, implementation ongoing  
- 📝 **Draft** - Initial documentation, implementation planned
- 🔄 **Updated Recently** - Documentation reflects latest changes

## 📝 Contributing to Documentation

### Documentation Standards
- Use clear, concise language
- Include practical examples
- Keep technical accuracy high
- Update the index when adding new docs

### File Naming Convention
- Use descriptive names with underscores: `feature_name_guide.md`
- Prefix with category for organization: `api_feature_guide.md`
- Keep names concise but informative

### Content Organization
- Start with overview/summary
- Include prerequisite information
- Provide step-by-step instructions
- Add troubleshooting sections
- Link to related documentation

### Spec Include Markers
- Include canonical spec sections into docs using markers:
  - `<!-- @spec-include path="docs/specifications/<Spec>.md" section="<Heading>" -->`
  - `<!-- @end-spec-include -->`
- Regenerate included sections with `mix pactis.docs.sync`.
- CI `docs-sync` workflow runs on PRs to `docs/**` and fails on drift.

---

**Need help finding something?** Check the main [README](../README.md) or browse the [Implementation Summary](IMPLEMENTATION_SUMMARY.md) for a technical overview.
