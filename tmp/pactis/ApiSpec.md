# API Specification

This document specifies the API of the Pactis project.

## Core Concepts

### Workspaces

All API calls are scoped to a workspace. A workspace is a security and organizational boundary for spec negotiations. All operations are scoped to workspaces with proper authentication and authorization.

### JSON-LD

The API uses JSON-LD (JSON for Linked Data) to provide semantic structure and interoperability. This enables different tools, systems, and organizations to understand and process negotiation data without tight coupling to Pactis's internal formats.

### Real-time Events

The system publishes events via Phoenix PubSub for real-time coordination. Clients can subscribe to these events to receive real-time updates on spec negotiations.

### Authentication

The API uses Bearer Token authentication. Clients must include an `Authorization` header with a valid Bearer token in all API requests.

### Error Handling

The API uses standard HTTP status codes to indicate the success or failure of an API request. In case of an error, the API will return a JSON object with an `error` and a `message` field.

## API Endpoints

Base path: `/api/v1`

## API Tokens

The API Tokens API allows users to create, list, view, and revoke their API tokens for programmatic access to the Pactis API.

### Endpoints

#### List API tokens

*   **GET** `/tokens`

    List all API tokens for the current user.

#### Create API token

*   **POST** `/tokens`

    Create a new API token.

    **Request body:**

    ```json
    {
      "token": {
        "name": "My CLI Token",
        "scopes": ["read:components", "write:components"],
        "expires_at": "2025-12-31T23:59:59Z"
      }
    }
    ```

#### Get API token

*   **GET** `/tokens/:id`

    Get details about a specific API token.

#### Revoke API token

*   **DELETE** `/tokens/:id`

    Revoke an API token.

## Authentication

The Authentication API handles user registration, login, and token refresh.

### Endpoints

#### Register user

*   **POST** `/register`

    Register a new user.

    **Request body:**

    ```json
    {
      "user": {
        "email": "user@example.com",
        "password": "securepassword123",
        "password_confirmation": "securepassword123",
        "username": "johndoe",
        "name": "John Doe"
      }
    }
    ```

#### Login

*   **POST** `/login`

    Login with email and password.

    **Request body:**

    ```json
    {
      "user": {
        "email": "user@example.com",
        "password": "securepassword123"
      }
    }
    ```

#### Refresh token

*   **POST** `/refresh`

    Refresh an authentication token.

    **Request body:**

    ```json
    {
      "refresh_token": "current_refresh_token"
    }
    ```

## Billing

The Billing API allows users to manage their subscriptions and view their usage.

### Endpoints

#### List pricing plans

*   **GET** `/billing/plans`

    List all pricing plans.

#### Get active subscription

*   **GET** `/billing/subscription/:org_id`

    Get the active subscription for an organization.

#### Create subscription

*   **POST** `/billing/subscription`

    Create a new subscription.

    **Request body:**

    ```json
    {
      "org_id": "org_123",
      "plan_id": "plan_abc"
    }
    ```

#### Cancel subscription

*   **DELETE** `/billing/subscription/:org_id`

    Cancel a subscription.

#### Get usage

*   **GET** `/billing/usage/:org_id`

    Get the usage for an organization.

#### List invoices

*   **GET** `/billing/invoices/:org_id`

    List all invoices for an organization.

#### Generate invoice

*   **POST** `/billing/invoices`

    Generate a new invoice.

    **Request body:**

    ```json
    {
      "org_id": "org_123"
    }
    ```

## Components

The Components API allows users to discover and download components.

### Endpoints

#### List components

*   **GET** `/components`

    Lists components with filtering and pagination.

#### Get component

*   **GET** `/components/:id`

    Gets a specific component by ID.

#### Get component as JSON-LD

*   **GET** `/components/:id/jsonld`

    Returns JSON-LD for a component/blueprint.

#### Download component

*   **POST** `/components/:id/download`

    Downloads a component in the specified framework format.

#### Get component stats

*   **GET** `/components/:id/stats`

    Gets component statistics and analytics.

#### Search components

*   **POST** `/components/search`

    Searches components with full-text search capabilities.

## Git

The Git API provides a Git Smart HTTP Protocol implementation for Pactis repositories.

### Endpoints

Base path: `/:owner/:repo`

#### Git references discovery

*   **GET** `/info/refs`

    This is the first step in Git clone/fetch/push operations. Returns available references (branches/tags) for the repository.

#### Git upload-pack

*   **POST** `/git-upload-pack`

    Serves repository data for clone/fetch operations.

#### Git receive-pack

*   **POST** `/git-receive-pack`

    Receives pushed changes and integrates with conversation system.

## Mem

The Mem API provides access to the Pactis Mem (memory) system.

### Endpoints

Base path: `/mem`

#### Get manifest

*   **GET** `/:workspace_id/:name/manifests/:ref`

    Get a manifest by reference.

#### Get blob

*   **GET** `/blobs/:digest`

    Get a blob by digest.

## Ops Changes

The Ops Changes API allows users to create and manage operational changes.

### Endpoints

Base path: `/ops/:workspace_id/changes`

#### Create change

*   **POST** `/`

    Create a new operational change.

#### Get change

*   **GET** `/:id`

    Get an operational change by ID.

#### Get change artifacts

*   **GET** `/:id/artifacts`

    Get the artifacts for an operational change.

#### Apply change

*   **POST** `/:id/apply`

    Apply an operational change.

## Ops Stream

The Ops Stream API provides a real-time stream of operational change events.

### Endpoints

Base path: `/ops/:workspace_id/changes/:id/stream`

#### Stream events

*   **GET** `/`

    Stream operational change events.

## Repository Content

The Repository Content API allows users to manage the content of their repositories.

### Endpoints

Base path: `/repos/:owner/:repo/contents`

#### Get repository content

*   **GET** `/*path`

    Returns file content for blobs or directory listing for trees.

#### Create or update file content

*   **PUT** `/*path`

    Creates a conversation-driven commit when content is modified.

#### Delete a file

*   **DELETE** `/*path`

    Delete a file.

## Repositories

The Repositories API allows users to manage their repositories.

### Endpoints

Base path: `/repos`

#### Get repository

*   **GET** `/:owner/:repo`

    Show a repository.

#### Create user repository

*   **POST** `/user/repos`

    Create a user repository.

#### Create organization repository

*   **POST** `/orgs/:org/repos`

    Create an organization repository.

#### List user repositories

*   **GET** `/users/:username/repos`

    List user repositories.

#### List organization repositories

*   **GET** `/orgs/:org/repos`

    List organization repositories.

#### Star a repository

*   **PUT** `/user/starred/:owner/:repo`

    Star a repository.

#### Fork a repository

*   **POST** `/:owner/:repo/forks`

    Fork a repository.

## Spec

The Spec API allows you to manage specification negotiations.

### Endpoints

Base path: `/spec/:workspace_id`

#### Create/Update Spec Request

*   **POST** `/requests`

#### Send Message

*   **POST** `/requests/:id/messages`

#### Subscribe to Updates

*   **GET** `/requests/:id/messages?since=<timestamp>`

#### Update Status

*   **POST** `/requests/:id/status`

#### Export Canonical JSON-LD

*   **GET** `/requests/:id/export.jsonld`

## Storage

The Storage API provides a simple way to serve files stored by the Pactis.FileStorage system during development.

### Endpoints

Base path: `/storage`

#### Serve file

*   **GET** `/*path`

    Serve a file from local storage.
