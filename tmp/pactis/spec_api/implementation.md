# Implementation Guide: Cross-Repository Spec Negotiation

## Quick Start

### 1. Authentication Setup
First, obtain a workspace-scoped API token:

```bash
# Create API token via Pactis web interface or CLI
curl -X POST https://pactis.dev/api/v1/tokens \
  -H "Authorization: Bearer <user_token>" \
  -d '{"name": "spec-negotiation", "workspace_id": "ws_123", "scopes": ["spec:read", "spec:write"]}'
```

### 2. Basic Integration

```javascript
// Node.js client example
class PactisSpecClient {
  constructor(apiUrl, workspaceId, token) {
    this.apiUrl = apiUrl;
    this.workspaceId = workspaceId;
    this.token = token;
    this.baseUrl = `${apiUrl}/api/v1/workspaces/${workspaceId}/spec`;
  }

  async createRequest(id, project, title, metadata = {}) {
    const response = await fetch(`${this.baseUrl}/requests`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ id, project, title, metadata })
    });
    return response.json();
  }

  async sendMessage(requestId, message, attachments = {}) {
    const response = await fetch(`${this.baseUrl}/requests/${requestId}/messages`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': crypto.randomUUID()
      },
      body: JSON.stringify({
        message,
        attachments_content: attachments
      })
    });
    return response.json();
  }

  async subscribe(requestId, callback) {
    // WebSocket or EventSource implementation
    const eventSource = new EventSource(
      `${this.baseUrl}/requests/${requestId}/events?token=${this.token}`
    );
    eventSource.onmessage = (event) => {
      callback(JSON.parse(event.data));
    };
  }
}
```

### 3. Mix Task Integration

Pactis provides Mix tasks for Elixir projects:

```bash
# Add to your Mix project
mix spec.create --id "schema-v2-migration" --project "my_service" --title "Migrate to schema v2"

# Send a proposal with attachment
mix spec.message --id "schema-v2-migration" --type proposal \
  --body "Propose backward-compatible migration" \
  --attach migration.patch

# Check for updates
mix spec.pull --id "schema-v2-migration" --since "2025-09-01T15:00:00Z"

# Update status
mix spec.status --id "schema-v2-migration" --set accepted
```

## Integration Patterns

### 1. CI/CD Integration

```yaml
# GitHub Actions example
name: Spec Negotiation
on:
  push:
    paths: ['schemas/**']

jobs:
  propose_changes:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Create spec request
      run: |
        curl -X POST ${{ secrets.PACTIS_BASE_URL }}/api/v1/workspaces/${{ secrets.WORKSPACE_ID }}/spec/requests \
          -H "Authorization: Bearer ${{ secrets.PACTIS_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d '{
            "id": "schema-update-${{ github.sha }}",
            "project": "${{ github.repository }}",
            "title": "Schema update from commit ${{ github.sha }}",
            "metadata": {
              "commit": "${{ github.sha }}",
              "branch": "${{ github.ref }}",
              "author": "${{ github.actor }}"
            }
          }'

    - name: Send proposal
      run: |
        git diff HEAD~1 schemas/ > schema.patch
        base64 schema.patch > schema.patch.b64
        
        curl -X POST ${{ secrets.PACTIS_BASE_URL }}/api/v1/workspaces/${{ secrets.WORKSPACE_ID }}/spec/requests/schema-update-${{ github.sha }}/messages \
          -H "Authorization: Bearer ${{ secrets.PACTIS_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d "{
            \"message\": {
              \"type\": \"proposal\",
              \"from\": {\"project\": \"${{ github.repository }}\", \"agent\": \"github-actions\"},
              \"body\": \"Automated schema update from commit ${{ github.sha }}\",
              \"attachments\": [\"schema.patch\"]
            },
            \"attachments_content\": {
              \"schema.patch\": \"$(cat schema.patch.b64)\"
            }
          }"
```

### 2. Webhook Integration

```javascript
// Express.js webhook handler
app.post('/pactis-webhook', (req, res) => {
  const { event_type, payload } = req.body;
  
  switch (event_type) {
    case 'spec_message':
      if (payload.message.type === 'question') {
        // Automatically respond to certain questions
        handleAutoResponse(payload);
      }
      break;
      
    case 'spec_status':
      if (payload.status === 'accepted') {
        // Trigger implementation workflow
        triggerImplementation(payload.request_id);
      }
      break;
  }
  
  res.status(200).send('OK');
});

async function handleAutoResponse(payload) {
  const { request_id, message } = payload;
  
  // Example: Auto-respond to version compatibility questions
  if (message.body.includes('compatibility')) {
    await cdfmClient.sendMessage(request_id, {
      type: 'comment',
      from: { project: 'auto-responder', agent: 'compatibility-bot' },
      body: 'This change maintains backward compatibility with versions 1.x through 2.x',
      ref: { path: 'COMPATIBILITY.md' }
    });
  }
}
```

### 3. Monitoring & Alerting

```javascript
// Monitoring service integration
class SpecNegotiationMonitor {
  constructor(cdfmClient, alerting) {
    this.client = cdfmClient;
    this.alerting = alerting;
    this.thresholds = {
      questionResponseTime: 24 * 60 * 60 * 1000, // 24 hours
      implementationTime: 7 * 24 * 60 * 60 * 1000, // 7 days
      blockedTime: 3 * 24 * 60 * 60 * 1000 // 3 days
    };
  }

  async monitorRequests() {
    const requests = await this.client.listRequests();
    
    for (const request of requests) {
      await this.checkResponseTimes(request);
      await this.checkImplementationProgress(request);
      await this.checkBlockedRequests(request);
    }
  }

  async checkResponseTimes(request) {
    const messages = await this.client.getMessages(request.id);
    const unansweredQuestions = messages
      .filter(m => m.type === 'question')
      .filter(m => !this.hasSubsequentResponse(m, messages));

    for (const question of unansweredQuestions) {
      const age = Date.now() - new Date(question.created_at).getTime();
      if (age > this.thresholds.questionResponseTime) {
        await this.alerting.send({
          type: 'question_timeout',
          request_id: request.id,
          question_id: question.id,
          age: age
        });
      }
    }
  }
}
```

## Error Handling

### 1. Network Resilience

```javascript
class ResilientCDFMClient extends PactisSpecClient {
  constructor(config) {
    super(config.apiUrl, config.workspaceId, config.token);
    this.retryAttempts = config.retryAttempts || 3;
    this.retryDelay = config.retryDelay || 1000;
    this.backoffMultiplier = config.backoffMultiplier || 2;
  }

  async sendMessageWithRetry(requestId, message, attachments = {}) {
    let lastError;
    
    for (let attempt = 1; attempt <= this.retryAttempts; attempt++) {
      try {
        return await this.sendMessage(requestId, message, attachments);
      } catch (error) {
        lastError = error;
        
        if (error.status === 409) {
          // Idempotency conflict - message already exists
          console.log('Message already exists, continuing...');
          return { status: 'duplicate' };
        }
        
        if (attempt < this.retryAttempts) {
          const delay = this.retryDelay * Math.pow(this.backoffMultiplier, attempt - 1);
          console.log(`Attempt ${attempt} failed, retrying in ${delay}ms...`);
          await this.sleep(delay);
        }
      }
    }
    
    throw lastError;
  }

  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### 2. Event Replay

```javascript
class EventReplayer {
  constructor(cdfmClient, storage) {
    this.client = cdfmClient;
    this.storage = storage;
  }

  async replayMissedEvents() {
    const lastProcessed = await this.storage.getLastProcessedTimestamp();
    const requests = await this.client.listRequests();
    
    for (const request of requests) {
      const messages = await this.client.getMessages(request.id, {
        since: lastProcessed
      });
      
      for (const message of messages) {
        await this.processMessage(request, message);
      }
    }
    
    await this.storage.setLastProcessedTimestamp(new Date());
  }

  async processMessage(request, message) {
    // Process message based on type
    console.log(`Processing ${message.type} for ${request.id}`);
    
    // Update local state
    await this.updateLocalState(request, message);
    
    // Trigger any necessary actions
    await this.handleMessageType(request, message);
  }
}
```

## Testing Strategies

### 1. Unit Testing

```javascript
// Jest test example
describe('Pactis Spec Client', () => {
  let client;
  let mockFetch;

  beforeEach(() => {
    mockFetch = jest.fn();
    global.fetch = mockFetch;
    client = new PactisSpecClient('http://test', 'ws_test', 'token');
  });

  test('creates spec request', async () => {
    mockFetch.mockResolvedValueOnce({
      json: () => Promise.resolve({ data: { id: 'test-req' } })
    });

    const result = await client.createRequest('test-req', 'test-project', 'Test');
    
    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining('/requests'),
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'Authorization': 'Bearer token'
        })
      })
    );
    expect(result.data.id).toBe('test-req');
  });

  test('handles idempotency correctly', async () => {
    mockFetch.mockResolvedValueOnce({
      status: 409,
      json: () => Promise.resolve({ error: 'duplicate' })
    });

    const message = {
      type: 'comment',
      from: { project: 'test' },
      body: 'Test message'
    };

    await expect(client.sendMessage('req-1', message)).rejects.toThrow();
  });
});
```

### 2. Integration Testing

```bash
#!/bin/bash
# Integration test script

# Start test Pactis instance
docker run -d --name pactis-test -p 4000:4000 pactis:test

# Wait for startup
sleep 10

# Create test workspace
WORKSPACE_ID=$(curl -X POST http://localhost:4000/api/v1/workspaces \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"name": "test-workspace"}' | jq -r '.data.id')

# Test full negotiation flow
REQUEST_ID="integration-test-$(date +%s)"

# 1. Create request
curl -X POST "http://localhost:4000/api/v1/workspaces/$WORKSPACE_ID/spec/requests" \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d "{\"id\": \"$REQUEST_ID\", \"project\": \"test\", \"title\": \"Integration test\"}"

# 2. Send proposal
curl -X POST "http://localhost:4000/api/v1/workspaces/$WORKSPACE_ID/spec/requests/$REQUEST_ID/messages" \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"message": {"type": "proposal", "from": {"project": "test"}, "body": "Test proposal"}}'

# 3. Accept proposal
curl -X POST "http://localhost:4000/api/v1/workspaces/$WORKSPACE_ID/spec/requests/$REQUEST_ID/messages" \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"message": {"type": "decision", "from": {"project": "reviewer"}, "body": "Accepted"}}'

# 4. Update status
curl -X POST "http://localhost:4000/api/v1/workspaces/$WORKSPACE_ID/spec/requests/$REQUEST_ID/status" \
  -H "Authorization: Bearer $TEST_TOKEN" \
  -d '{"status": "accepted"}'

# 5. Export JSON-LD
curl -H "Authorization: Bearer $TEST_TOKEN" \
  "http://localhost:4000/api/v1/workspaces/$WORKSPACE_ID/spec/requests/$REQUEST_ID/export.jsonld"

# Cleanup
docker stop pactis-test
docker rm pactis-test

echo "Integration test completed successfully"
```

## Best Practices

1. **Use Idempotency Keys**: Always include idempotency keys for message creation
2. **Handle Duplicates**: Check for 409 Conflict responses and handle gracefully
3. **Subscribe Early**: Subscribe to events before creating requests to avoid missing notifications
4. **Batch Updates**: Group related messages to reduce API calls
5. **Monitor Health**: Implement health checks and alerting for negotiation bottlenecks
6. **Archive Completed**: Archive or clean up completed negotiations to reduce noise
7. **Document Decisions**: Include detailed rationale in decision messages
8. **Version Attachments**: Use semantic versioning for attachment references

This implementation guide provides the foundation for integrating with Pactis's negotiation system across various platforms and languages.
