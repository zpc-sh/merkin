# Usage Examples & Best Practices

## Real-World Scenarios

### Scenario 1: API Version Migration

A microservices architecture needs to coordinate an API version upgrade across multiple services.

**Participants:**
- `user-service` (API provider)
- `payment-service` (API consumer) 
- `notification-service` (API consumer)
- `frontend-app` (API consumer)

#### Step 1: Initiate Migration Proposal

```bash
# user-service creates the negotiation
curl -X POST "https://pactis.dev/api/v1/workspaces/acme-prod/spec/requests" \
  -H "Authorization: Bearer $USER_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "user-api-v3-migration",
    "project": "user-service",
    "title": "Migrate User API to v3.0 with enhanced security",
    "metadata": {
      "breaking_changes": true,
      "migration_deadline": "2025-11-01",
      "deprecation_period": "6 months",
      "impact": "all consuming services"
    }
  }'
```

#### Step 2: Detailed Proposal with Migration Plan

```bash
# Prepare migration documentation
echo "# User API v3 Migration Plan
## Breaking Changes
- Authentication now requires JWT tokens
- User ID format changed from integer to UUID
- Pagination parameters renamed

## Timeline
- 2025-09-15: Migration plan review
- 2025-10-01: Begin implementation
- 2025-10-15: Testing phase
- 2025-11-01: Production deployment

## Backward Compatibility
- v2 API maintained for 6 months
- Automatic migration tool provided
- Gradual traffic switching supported
" > migration-plan.md

# Convert to base64
base64 migration-plan.md > migration-plan.b64

# Send proposal with attachments
curl -X POST "https://pactis.dev/api/v1/workspaces/acme-prod/spec/requests/user-api-v3-migration/messages" \
  -H "Authorization: Bearer $USER_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d "{
    \"message\": {
      \"type\": \"proposal\",
      \"from\": {\"project\": \"user-service\", \"agent\": \"api-team\"},
      \"body\": \"Proposing User API v3 with enhanced security and modern patterns. Please review the detailed migration plan.\",
      \"ref\": {\"path\": \"api/v3/openapi.yaml\"},
      \"attachments\": [\"migration-plan.md\", \"v3-openapi.yaml\", \"migration-tool.sh\"]
    },
    \"attachments_content\": {
      \"migration-plan.md\": \"$(cat migration-plan.b64)\"
    }
  }"
```

#### Step 3: Consumer Services Respond

```javascript
// payment-service automated response
const cdfmClient = new PactisSpecClient(process.env.PACTIS_BASE_URL, 'acme-prod', process.env.PAYMENT_TOKEN);

// Subscribe to updates
cdfmClient.subscribe('user-api-v3-migration', async (event) => {
  if (event.type === 'spec_message' && event.payload.message.type === 'proposal') {
    // Automated impact analysis
    const impact = await analyzeAPIImpact(event.payload.message);
    
    if (impact.riskLevel === 'high') {
      await cdfmClient.sendMessage('user-api-v3-migration', {
        type: 'question',
        from: {project: 'payment-service', agent: 'impact-analyzer'},
        body: `High impact detected: ${impact.breakingChanges.length} breaking changes affect our payment workflows. Can we get additional transition support?`,
        attachments: ['impact-analysis.json']
      }, {
        'impact-analysis.json': Buffer.from(JSON.stringify(impact)).toString('base64')
      });
    } else {
      await cdfmClient.sendMessage('user-api-v3-migration', {
        type: 'decision', 
        from: {project: 'payment-service', agent: 'api-team'},
        body: `Approved with conditions: Need 2 weeks for testing after staging deployment.`
      });
    }
  }
});
```

#### Step 4: Address Questions and Concerns

```bash
# user-service responds to payment-service concerns  
curl -X POST "https://pactis.dev/api/v1/workspaces/acme-prod/spec/requests/user-api-v3-migration/messages" \
  -H "Authorization: Bearer $USER_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "type": "comment",
      "from": {"project": "user-service", "agent": "alice@acme.com"},
      "body": "Great question! We will provide a compatibility shim for payment workflows and dedicated migration support. Updated timeline allows for 2-week testing period per service.",
      "attachments": ["payment-service-migration-guide.md"]
    }
  }'
```

#### Step 5: Final Consensus and Implementation

```bash
# Update status after all approvals
curl -X POST "https://pactis.dev/api/v1/workspaces/acme-prod/spec/requests/user-api-v3-migration/status" \
  -H "Authorization: Bearer $USER_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "accepted"}'

# Later, mark as in progress
curl -X POST "https://pactis.dev/api/v1/workspaces/acme-prod/spec/requests/user-api-v3-migration/status" \
  -H "Authorization: Bearer $USER_SERVICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "in_progress"}'
```

### Scenario 2: Database Schema Evolution

A shared database schema needs updates that affect multiple applications.

#### Automated Schema Change Workflow

```yaml
# .github/workflows/schema-negotiation.yml
name: Database Schema Negotiation
on:
  push:
    paths: ['db/migrations/**']

jobs:
  negotiate_schema_change:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Detect schema changes
      id: changes
      run: |
        CHANGED_FILES=$(git diff --name-only HEAD~1 db/migrations/)
        echo "changed_files=$CHANGED_FILES" >> $GITHUB_OUTPUT
        
        # Analyze impact
        python scripts/analyze_schema_impact.py $CHANGED_FILES > impact.json
    
    - name: Create negotiation request
      run: |
        REQUEST_ID="schema-change-$(date +%Y%m%d)-$(git rev-parse --short HEAD)"
        
        curl -X POST "${{ secrets.PACTIS_BASE_URL }}/api/v1/workspaces/${{ secrets.WORKSPACE_ID }}/spec/requests" \
          -H "Authorization: Bearer ${{ secrets.PACTIS_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d "{
            \"id\": \"$REQUEST_ID\",
            \"project\": \"database-migrations\",
            \"title\": \"Schema change: ${{ steps.changes.outputs.changed_files }}\",
            \"metadata\": {
              \"commit\": \"${{ github.sha }}\",
              \"author\": \"${{ github.actor }}\",
              \"pr_number\": \"${{ github.event.number }}\",
              \"impact_level\": \"$(jq -r '.impact_level' impact.json)\"
            }
          }"
          
        echo "REQUEST_ID=$REQUEST_ID" >> $GITHUB_ENV

    - name: Send migration proposal
      run: |
        # Include schema diff and impact analysis
        git diff HEAD~1 db/ > schema.diff
        base64 schema.diff > schema.diff.b64
        base64 impact.json > impact.json.b64
        
        curl -X POST "${{ secrets.PACTIS_BASE_URL }}/api/v1/workspaces/${{ secrets.WORKSPACE_ID }}/spec/requests/$REQUEST_ID/messages" \
          -H "Authorization: Bearer ${{ secrets.PACTIS_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d "{
            \"message\": {
              \"type\": \"proposal\",
              \"from\": {\"project\": \"database-migrations\", \"agent\": \"github-actions\"},
              \"body\": \"Automated schema migration proposal from commit ${{ github.sha }}\",
              \"ref\": {\"path\": \"db/migrations\"},
              \"attachments\": [\"schema.diff\", \"impact.json\", \"rollback.sql\"]
            },
            \"attachments_content\": {
              \"schema.diff\": \"$(cat schema.diff.b64)\",
              \"impact.json\": \"$(cat impact.json.b64)\"
            }
          }"

    - name: Wait for approval
      timeout-minutes: 60
      run: |
        # Poll for approval
        while true; do
          STATUS=$(curl -s -H "Authorization: Bearer ${{ secrets.PACTIS_TOKEN }}" \
            "${{ secrets.PACTIS_BASE_URL }}/api/v1/workspaces/${{ secrets.WORKSPACE_ID }}/spec/requests/$REQUEST_ID" \
            | jq -r '.data.status')
            
          case $STATUS in
            "accepted")
              echo "Schema change approved!"
              exit 0
              ;;
            "rejected")
              echo "Schema change rejected"
              exit 1
              ;;
            *)
              echo "Status: $STATUS, waiting..."
              sleep 30
              ;;
          esac
        done
```

### Scenario 3: Configuration Management

Coordinating configuration changes across a distributed system.

#### Configuration Change Negotiation

```python
#!/usr/bin/env python3
"""
Configuration change coordination script
Usage: ./config_negotiator.py --env production --change redis_timeout
"""

import json
import time
import argparse
from datetime import datetime, timezone
from pactis_client import PactisSpecClient

class ConfigNegotiator:
    def __init__(self, workspace_id, token):
        self.client = PactisSpecClient(
            api_url="https://pactis.dev",
            workspace_id=workspace_id,
            token=token
        )
    
    def propose_config_change(self, env, change_type, details):
        request_id = f"config-{env}-{change_type}-{int(time.time())}"
        
        # Create request
        request = self.client.create_request(
            id=request_id,
            project="config-management",
            title=f"Configuration change: {change_type} in {env}",
            metadata={
                "environment": env,
                "change_type": change_type,
                "risk_level": self._assess_risk(change_type),
                "rollback_plan": "automated",
                "estimated_downtime": "0 minutes"
            }
        )
        
        # Send detailed proposal
        proposal = {
            "type": "proposal",
            "from": {"project": "config-management", "agent": "config-bot"},
            "body": f"Proposing {change_type} configuration change in {env} environment",
            "ref": {"path": f"config/{env}.yaml", "json_pointer": f"/{change_type}"},
            "attachments": ["config-diff.yaml", "impact-analysis.json", "rollback-plan.md"]
        }
        
        attachments = {
            "config-diff.yaml": self._generate_config_diff(env, change_type, details),
            "impact-analysis.json": self._generate_impact_analysis(env, change_type),
        }
        
        message = self.client.send_message(request_id, proposal, attachments)
        print(f"Created negotiation request: {request_id}")
        return request_id
    
    def monitor_approval_process(self, request_id, timeout_minutes=30):
        """Monitor the approval process with automated responses"""
        start_time = time.time()
        
        def handle_event(event):
            if event['type'] == 'spec_message':
                message = event['payload']['message']
                
                if message['type'] == 'question':
                    # Auto-respond to common questions
                    self._handle_auto_response(request_id, message)
                
                elif message['type'] == 'decision':
                    return message['body']  # Return decision
        
        # Subscribe to events
        self.client.subscribe(request_id, handle_event)
        
        # Poll for completion
        while (time.time() - start_time) < (timeout_minutes * 60):
            request = self.client.get_request(request_id)
            
            if request['status'] in ['accepted', 'rejected']:
                return request['status']
            
            time.sleep(10)
        
        raise TimeoutError(f"Approval process timed out after {timeout_minutes} minutes")
    
    def _handle_auto_response(self, request_id, question):
        """Handle common questions automatically"""
        body = question['body'].lower()
        
        if 'rollback' in body:
            response = {
                "type": "comment",
                "from": {"project": "config-management", "agent": "auto-responder"},
                "body": "Rollback plan: Configuration changes are applied via GitOps. Rollback is automatic via git revert within 30 seconds.",
                "ref": {"path": "docs/rollback-procedure.md"}
            }
            self.client.send_message(request_id, response)
        
        elif 'downtime' in body:
            response = {
                "type": "comment", 
                "from": {"project": "config-management", "agent": "auto-responder"},
                "body": "Zero-downtime deployment: Configuration is hot-reloaded without service restart. No downtime expected.",
            }
            self.client.send_message(request_id, response)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--env', required=True, choices=['staging', 'production'])
    parser.add_argument('--change', required=True, help='Configuration change type')
    parser.add_argument('--value', help='New configuration value')
    args = parser.parse_args()
    
    negotiator = ConfigNegotiator(
        workspace_id="acme-prod",
        token=os.environ['PACTIS_TOKEN']
    )
    
    # Propose change
    request_id = negotiator.propose_config_change(
        env=args.env,
        change_type=args.change,
        details={"value": args.value}
    )
    
    # Monitor for approval
    try:
        result = negotiator.monitor_approval_process(request_id, timeout_minutes=30)
        print(f"Negotiation result: {result}")
        
        if result == 'accepted':
            print("Proceeding with configuration change...")
            # Trigger actual configuration deployment
        else:
            print("Configuration change was rejected")
            
    except TimeoutError as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
```

## Best Practices

### 1. Message Design Patterns

#### Clear Communication

```json
// Good: Specific, actionable proposal
{
  "type": "proposal",
  "body": "Add rate limiting to user registration endpoint: 5 requests/minute per IP, 10 requests/hour per user account",
  "ref": {"path": "api/routes/auth.js", "json_pointer": "/register"},
  "attachments": ["rate-limit-config.json", "load-test-results.pdf"]
}

// Poor: Vague, unclear request  
{
  "type": "proposal",
  "body": "We should add some rate limiting stuff"
}
```

#### Structured References

```json
// Good: Precise file and location reference
{
  "ref": {
    "path": "config/database.yaml",
    "json_pointer": "/connection_pool/max_connections",
    "line_number": 45
  }
}

// Good: Multiple file references for complex changes
{
  "ref": {
    "files": [
      {"path": "api/models/user.js", "json_pointer": "/schema/email"},
      {"path": "database/migrations/20250901_user_email.sql"},
      {"path": "tests/user_validation.test.js", "json_pointer": "/email_tests"}
    ]
  }
}
```

### 2. Attachment Organization

```bash
# Good: Organized attachment structure
attachments/
├── analysis/
│   ├── performance-impact.json
│   ├── security-review.pdf
│   └── compatibility-matrix.csv
├── implementation/
│   ├── migration.sql
│   ├── config-changes.yaml
│   └── deployment-script.sh
└── documentation/
    ├── user-guide.md
    ├── api-changes.md
    └── rollback-procedure.md
```

### 3. Workflow Automation

#### Approval Routing

```yaml
# Pactis workflow configuration (.pactis/workflows.yml)
approval_routes:
  database_changes:
    required_approvers: ["dba-team", "backend-team"]
    auto_approve_if:
      - risk_level: "low"
      - change_type: "index_addition"
    notify:
      - slack: "#database-changes"
      - email: "dba@company.com"
  
  api_changes:
    required_approvers: ["api-team"]
    additional_approvers_if:
      breaking_changes: true
      approvers: ["frontend-team", "mobile-team", "partners"]
    
  config_changes:
    auto_approve_if:
      - environment: "staging"
    required_approvers_if:
      - environment: "production"
        approvers: ["devops-team", "security-team"]
```

#### Integration Hooks

```javascript
// Webhook handler for external integrations
app.post('/pactis-webhook', async (req, res) => {
  const { event_type, payload } = req.body;
  
  switch (event_type) {
    case 'spec_status':
      if (payload.status === 'accepted') {
        // Trigger CI/CD pipeline
        await jenkins.build('deploy-config-changes', {
          request_id: payload.request_id,
          workspace_id: payload.workspace_id
        });
      }
      break;
      
    case 'spec_message':
      if (payload.message.type === 'question') {
        // Create Jira ticket for questions requiring manual review
        await jira.createIssue({
          summary: `Pactis Question: ${payload.message.body}`,
          description: `Request: ${payload.request_id}\nFrom: ${payload.message.from.project}`,
          issueType: 'Task',
          labels: ['pactis-negotiation']
        });
      }
      break;
  }
  
  res.status(200).send('OK');
});
```

### 4. Error Recovery Patterns

#### Idempotent Operations

```javascript
// Always use idempotency keys for message creation
const createMessageSafely = async (requestId, message) => {
  const idempotencyKey = `${requestId}-${message.type}-${Date.now()}-${crypto.randomUUID()}`;
  
  try {
    return await cdfmClient.sendMessage(requestId, message, {}, idempotencyKey);
  } catch (error) {
    if (error.status === 409) {
      // Message already exists, fetch existing
      console.log('Message already exists, continuing...');
      return await cdfmClient.getMessages(requestId, {since: new Date(Date.now() - 60000)});
    }
    throw error;
  }
};
```

#### Circuit Breaker Pattern

```javascript
class ResilientCDFMClient {
  constructor(config) {
    this.client = new PactisSpecClient(config);
    this.circuitBreaker = new CircuitBreaker(this.client, {
      timeout: 10000,
      errorThresholdPercentage: 50,
      resetTimeout: 30000
    });
  }
  
  async sendMessage(requestId, message) {
    try {
      return await this.circuitBreaker.fire('sendMessage', requestId, message);
    } catch (error) {
      // Fallback: queue for retry
      await this.queueForRetry(requestId, message);
      throw new Error('Pactis temporarily unavailable, message queued for retry');
    }
  }
  
  async queueForRetry(requestId, message) {
    await redis.lpush('pactis-retry-queue', JSON.stringify({
      requestId,
      message,
      timestamp: Date.now()
    }));
  }
}
```

### 5. Monitoring & Observability

#### Metrics Collection

```javascript
const negotiationMetrics = {
  // Track negotiation velocity
  trackNegotiationDuration: (requestId, startTime, endTime) => {
    const duration = endTime - startTime;
    metrics.histogram('pactis.negotiation.duration', duration, {
      tags: {request_id: requestId}
    });
  },
  
  // Track approval rates
  trackApprovalRate: (approved, rejected) => {
    metrics.gauge('pactis.approval.rate', approved / (approved + rejected));
  },
  
  // Track message response times
  trackResponseTime: (questionTime, responseTime) => {
    const responseDelay = responseTime - questionTime;
    metrics.histogram('pactis.response.time', responseDelay);
  }
};
```

These examples demonstrate how Pactis's negotiation system enables sophisticated coordination workflows while maintaining simplicity and reliability.
