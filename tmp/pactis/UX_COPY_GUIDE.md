# UX Copy and Presentation Guidelines (Components Gallery)

This guide captures consistent language and presentation patterns for the Components and Design Systems views.

## Labels and Headings
- Page titles: “Components”, “Design systems”.
- Section headers: “Components”, “Design systems”.
- CTAs: “View all”.
- Sort control: “Sort by:”, options “Name”, “Example count”.

## Card Presentation
- Title: Entire title is a focusable link; underline or subtle border on hover.
- Preview: Prefer SVG markup (if available), else fixed-aspect image; fallback “No preview”.
- Badge (count): Show a small numeric badge (Examples count) beside the title.
- “Other names”: Show an italic line above description when present.
- Meta lists: “Tech” and “Features” subheadings; pill-like tags below each.

## Empty and Feedback States
- Empty components list: “No components found” + “Try adjusting your search or filters.”
- Keep toast/flash concise: “Saved.” “Deployment started.” “RPC error.”

## Accessibility
- Icons with links: Use SR-only labels like “{Name} on GitHub”.
- Headings/structure: Use semantic list markup (ul/li) for grids and lists.

## Data Alignment
- Components: name, slug, description (markdown → HTML), examples_count, other_names, image, svg_markup, tech (list), features (list), updated_at.
- Design systems: name, url, image, organisation, tech_lookup, features_lookup, github_url, storybook_url, figma_url, component_examples_count, last_reviewed.

## Implementation Notes
- Prefer server-side sorting over client-only DOM reordering.
- Use typed queries for RPC with field presets (card/header/minimal).
- Provide SR labels for icon-only actions.

This copy should be reflected in: toolbar labels, card subheadings, and badge usage.
