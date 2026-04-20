# Getting Started with Blueprint Forge

Welcome to Blueprint Forge - the definitive platform for sharing and managing reusable Ash Framework resource patterns. This guide will walk you through everything from basic installation to advanced multi-format code generation.

## What is Blueprint Forge?

Blueprint Forge is a sophisticated multi-format code generation platform that allows you to:

- **Generate multiple output formats** from a single Ash resource definition
- **Share reusable patterns** across the Elixir/Phoenix community
- **Maintain code quality** with built-in testing and accessibility auditing
- **Migrate safely** between blueprint versions with intelligent conflict resolution

### Supported Output Formats

- **Phoenix HTML**: LiveView applications with components and templates
- **Terminal UI**: Rich terminal interfaces using Raxol
- **REST API**: JSON APIs with OpenAPI documentation
- **Admin Panel**: Complete admin interfaces with CRUD operations

## Quick Start

### 1. Installation

Add Blueprint Forge to your Phoenix application:

```elixir
# mix.exs
defp deps do
  [
    {:pactis, "~> 1.0"}
  ]
end
```

Run the installation:

```bash
mix deps.get
mix pactis.setup
```

### 2. Your First Blueprint

Let's create a user management blueprint that generates multiple formats:

```bash
# Create a new blueprint
mix blueprint.create user_management --domain MyApp.Accounts

# Install with multiple formats
mix blueprint.install user_management --formats phoenix_html,admin_panel,rest_api
```

This single command generates:

- **LiveView pages** for user management (index, show, form)
- **Admin panel** with dashboard and bulk operations  
- **REST API** with full CRUD endpoints
- **Tests** for all generated components
- **Documentation** with OpenAPI specs

### 3. Explore Generated Code

After installation, you'll find:

```
lib/my_app_web/live/users/           # LiveView pages
lib/my_app_web/admin/users/          # Admin interface
lib/my_app_web/api/users/            # REST API controllers
test/my_app_web/live/users/          # Comprehensive tests
priv/static/api/                     # OpenAPI documentation
```

### 4. Preview Before Installing

Always preview what will be generated:

```bash
# See what would be created
mix blueprint.install user_management --dry-run --all-formats

# Test specific formats
mix blueprint.install user_management --dry-run --formats phoenix_html,admin_panel
```

## Core Concepts

### Blueprints

A blueprint is a versioned template that defines:

- **Ash Resource structure** (attributes, relationships, actions)
- **Format manifests** (how to render each output format)
- **Installation metadata** (dependencies, configuration)
- **Quality metrics** (test coverage, accessibility compliance)

### Multi-Format Generation

Blueprint Forge embraces platform differences rather than abstracting them away:

```bash
# Generate web interface optimized for Phoenix
mix blueprint.install blog --format phoenix_html

# Generate terminal interface optimized for CLI tools  
mix blueprint.install blog --format terminal_ui

# Generate admin interface with advanced features
mix blueprint.install blog --format admin_panel

# Generate all formats for maximum flexibility
mix blueprint.install blog --all-formats
```

### Semantic Themes

Universal design tokens that translate across formats:

```elixir
# Define once, use everywhere
theme = Pactis.Themes.default()

# Automatically generates:
# - CSS custom properties for web
# - ANSI colors for terminal
# - Platform themes for native apps
```

## Common Workflows

### Installing Blueprints

```bash
# Basic installation
mix blueprint.install user_auth --domain MyApp.Accounts

# With specific format
mix blueprint.install user_auth --format phoenix_html

# Multiple formats
mix blueprint.install user_auth --formats phoenix_html,rest_api,admin_panel

# Preview first
mix blueprint.install user_auth --dry-run

# Force overwrite conflicts
mix blueprint.install user_auth --force
```

### Managing Conflicts

When files already exist, Blueprint Forge provides intelligent conflict resolution:

```bash
# Interactive conflict resolution (default)
mix blueprint.install user_auth

# Automatic safe merging
mix blueprint.install user_auth --strategy automatic

# Manual resolution guide
mix blueprint.install user_auth --strategy manual

# Always create backups
mix blueprint.install user_auth --backup
```

### Blueprint Migration

Keep your blueprints up-to-date safely:

```bash
# Check available updates
mix blueprint.migrate user_auth --list

# Preview migration
mix blueprint.migrate user_auth --plan --to 2.1.0

# Interactive migration
mix blueprint.migrate user_auth --to 2.1.0

# Rollback if needed
mix blueprint.migrate user_auth --rollback 1.5.0

# View migration history
mix blueprint.migrate user_auth --history
```

## Advanced Features

### Custom Themes

Create branded experiences across all formats:

```elixir
# config/config.exs
config :pactis, :theme,
  colors: %{
    primary: "#2563EB",    # Your brand blue
    secondary: "#64748B",   
    success: "#059669",
    warning: "#D97706",
    danger: "#DC2626"
  },
  typography: %{
    font_family: "Inter, system-ui, sans-serif",
    heading_weight: 600
  }
```

### Performance Monitoring

Track performance across formats:

```elixir
# Profile blueprint generation
Pactis.Performance.profile_generation(blueprint, [:phoenix_html, :admin_panel])

# Measure runtime performance
Pactis.Performance.measure_runtime(component, :phoenix_html)

# Compare formats
Pactis.Performance.compare_formats(blueprint, [:phoenix_html, :terminal_ui])

# Generate performance report
Pactis.Performance.generate_report(results)
```

### Accessibility Auditing

Ensure inclusive design across all formats:

```elixir
# Audit single component
Pactis.Accessibility.audit_component(component, :phoenix_html)

# Comprehensive audit
Pactis.Accessibility.comprehensive_audit(component)

# Check color contrast
Pactis.Accessibility.check_contrast("#000000", "#FFFFFF")

# Generate accessibility report
Pactis.Accessibility.generate_report(audit_results)
```

### Visual Testing

Prevent visual regressions across formats:

```elixir
# Test component visually
Pactis.Testing.VisualRegression.test_component(
  component, 
  [:phoenix_html, :terminal_ui]
)

# Test responsive design
Pactis.Testing.VisualRegression.test_responsive(
  component,
  :phoenix_html,
  breakpoints: [:mobile, :tablet, :desktop]
)

# Compare themes
Pactis.Testing.VisualRegression.compare_themes(
  component,
  [:default, :dark, :high_contrast]
)
```

## Creating Your Own Blueprints

### Blueprint Structure

A typical blueprint includes:

```elixir
defmodule MyApp.Blueprints.UserAuth do
  use Pactis.Blueprint

  blueprint do
    name "user_auth"
    description "Complete user authentication system"
    version "1.0.0"
    
    formats [:phoenix_html, :rest_api, :admin_panel]
    
    resource do
      # Ash resource definition
      attributes do
        uuid_primary_key :id
        attribute :email, :string, allow_nil?: false
        attribute :password_hash, :string, private?: true
        # ... more attributes
      end
      
      # Relationships, actions, etc.
    end
    
    # Format-specific configurations
    format :phoenix_html do
      themes [:default, :dark]
      components [:user_form, :user_table, :auth_modal]
    end
    
    format :admin_panel do
      features [:dashboard, :bulk_operations, :export]
    end
  end
end
```

### Publishing Blueprints

```bash
# Create blueprint package
mix blueprint.create my_awesome_pattern --publish

# Add metadata
mix blueprint.configure my_awesome_pattern \
  --description "Awesome pattern for X" \
  --tags "auth,admin,crud" \
  --license "MIT"

# Publish to registry
mix blueprint.publish my_awesome_pattern
```

## Best Practices

### Format Selection

Choose formats based on your needs:

- **Phoenix HTML**: Core web application interfaces
- **Admin Panel**: Internal tools and dashboards  
- **REST API**: Mobile apps, integrations, microservices
- **Terminal UI**: CLI tools, developer utilities

### Theme Consistency

Use semantic tokens for consistent branding:

```elixir
# Good: Semantic meaning
colors: %{
  primary: "#2563EB",
  success: "#059669", 
  warning: "#D97706"
}

# Avoid: Specific colors without semantic meaning
colors: %{
  blue_500: "#2563EB",
  green_600: "#059669"
}
```

### Testing Strategy

Test generated code thoroughly:

```bash
# Run all tests after installation
mix test

# Visual regression tests
mix blueprint.test.visual user_auth

# Accessibility audit
mix blueprint.test.accessibility user_auth

# Performance benchmarks
mix blueprint.test.performance user_auth
```

### Migration Planning

Plan migrations carefully:

```bash
# Always validate first
mix blueprint.migrate user_auth --validate --to 2.0.0

# Use dry-run to preview
mix blueprint.migrate user_auth --dry-run --to 2.0.0

# Create backups
mix blueprint.migrate user_auth --backup --to 2.0.0
```

## Troubleshooting

### Common Issues

**Installation Conflicts**
```bash
# View conflicts
mix blueprint.install user_auth --dry-run

# Resolve interactively
mix blueprint.install user_auth --strategy interactive

# Force overwrite (careful!)
mix blueprint.install user_auth --force
```

**Generation Errors**
```bash
# Check blueprint validity
mix blueprint.validate user_auth

# View detailed logs
mix blueprint.install user_auth --verbose

# Test specific format
mix blueprint.install user_auth --format phoenix_html --dry-run
```

**Performance Issues**
```bash
# Profile generation
mix blueprint.profile user_auth

# Check resource usage
mix blueprint.install user_auth --monitor

# Optimize templates
mix blueprint.optimize user_auth
```

### Getting Help

- **Documentation**: Browse `/docs` directory for detailed guides
- **Examples**: Check `examples/` for sample blueprints
- **Community**: Join the Elixir Forum's Blueprint Forge section
- **Issues**: Report bugs on GitHub

## Examples

### E-commerce Store

```bash
# Create complete e-commerce blueprint
mix blueprint.install ecommerce_store --all-formats
# Generates: Product catalog, shopping cart, admin panel, API
```

### Blog Platform  

```bash
# Generate blog with admin and API
mix blueprint.install blog_platform --formats phoenix_html,admin_panel,rest_api
# Generates: Article management, admin dashboard, REST API
```

### CRM System

```bash
# Terminal-based CRM for CLI power users
mix blueprint.install crm_system --format terminal_ui
# Generates: Rich terminal interface with keyboard shortcuts
```

## Next Steps

1. **Explore Examples**: Check out the example blueprints in `/examples`
2. **Read the Design Document**: Understand the architecture in `/docs/blueprints.md`
3. **Create Your First Blueprint**: Start with a simple pattern you use often
4. **Join the Community**: Share your blueprints and learn from others
5. **Contribute**: Help improve Blueprint Forge for everyone

## Summary

Blueprint Forge transforms how you build Ash Framework applications by:

- **Accelerating development** with proven patterns
- **Ensuring quality** with built-in testing and accessibility
- **Supporting growth** with safe migration and updates  
- **Fostering community** through shared, reusable components

Start with the basic installation and explore the rich ecosystem of multi-format code generation. Whether you're building web apps, APIs, admin panels, or terminal tools, Blueprint Forge provides the foundation for consistent, high-quality development.

Happy coding! 🚀
