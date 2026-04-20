# Tokens Best Practices (Pactis)

This guide shows how to structure design tokens to drive branding and typography across services.

## JSON-LD Shape (EffectiveTokenSet tokens)
- Color
  - `color.primary.value`: hex color (e.g., `#FD4F00`)
- Typography
  - `typography.base`: base font size (px/rem)
  - `typography.h1..h6`: heading sizes (non-increasing ramp)
  - `typography.lineHeight`: default line-height
- Spacing
  - `spacing.scale`: strictly increasing array (px) e.g., `[4,8,12,16,20,24,32]`
- Fonts
  - `fonts.imports[]`: CSS `@import` URLs (e.g., Google Fonts)
  - `fonts.body`, `fonts.mono`: font-family stacks

Example:
```json
{
  "color": {"primary": {"value": "#FD4F00"}},
  "typography": {"base": "16px", "h1": "32px", "h2": "24px", "h3": "20px", "h4": "18px", "h5": "16px", "h6": "14px", "lineHeight": "1.5"},
  "spacing": {"scale": [4,8,12,16,20,24,32]},
  "fonts": {"imports": ["https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap"], "body": "Inter, system-ui, sans-serif", "mono": "JetBrains Mono, ui-monospace, monospace"}
}
```

## Constraints
- Typography ramp: `h1 >= h2 >= ... >= h6 >= base` (sizes)
- Spacing scale: strictly increasing; optional constant step (e.g., `4px`)
- Contrast: `color.primary` should contrast (>= 4.5) with either black or white

## Validation
- Run: `mix pactis.design.validate --owner <org> --repo <repo> --version vX`
- Or from a file: `mix pactis.design.validate --file priv/examples/tokens.example.json --step 4px`
- Manifest validation: `mix pactis.service.validate`

## Driving Branding
- Dynamic logo: `/branding/logo.svg?owner&repo&org_version&text=&size=&variant=&pattern=&bg=`
- Theme CSS: `/branding/theme.css?owner&repo&org_version`
- Typography-only: `/branding/typography.css?owner&repo&org_version`
