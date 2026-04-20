# Generate ALL the blueprint registry resources (single-tenant, GitHub-style)

# Check what ash_authentication setup commands are available
mix help | grep auth

# If ash_authentication has setup tasks, run them first
# Otherwise we'll add authentication manually to the User resource

# User accounts with authentication (add auth extensions later)
mix ash.gen.resource Pactis.Accounts.User users \
  --attribute email:ci_string:required \
  --attribute username:string:required \
  --attribute name:string \
  --attribute avatar_url:string \
  --attribute bio:string \
  --attribute github_handle:string \
  --attribute website_url:string \
  --attribute location:string \
  --attribute public_email:boolean:default=false \
  --attribute email_verified:boolean:default=false \
  --attribute status:atom:values=active,suspended,deleted:default=active \
  --attribute hashed_password:string

# Organizations (teams/companies)
mix ash.gen.resource Pactis.Accounts.Organization organizations \
  --attribute name:string:required \
  --attribute slug:string:required \
  --attribute description:string \
  --attribute avatar_url:string \
  --attribute website_url:string \
  --attribute location:string \
  --attribute visibility:atom:values=public,private:default=public

# Organization memberships
mix ash.gen.resource Pactis.Accounts.Membership memberships \
  --attribute role:atom:values=owner,admin,member:default=member \
  --attribute status:atom:values=active,pending,declined:default=pending

# Categories for organizing blueprints
  --attribute name:string:required \
  --attribute slug:string:required \
  --attribute description:text \
  --attribute color:string \
  --attribute icon:string \
  --attribute sort_order:integer:default=0

# Blueprint resources (the main attraction)
mix ash.gen.resource Pactis.Core.Blueprint blueprints \
  --attribute name:string:required \
  --attribute slug:string:required \
  --attribute description:text \
  --attribute readme:text \
  --attribute resource_definition:map:required \
  --attribute component_files:map \
  --attribute version:string:default="1.0.0" \
  --attribute visibility:atom:values=public,private:default=public \
  --attribute license:string:default="MIT" \
  --attribute tags:array \
  --attribute downloads_count:integer:default=0 \
  --attribute stars_count:integer:default=0 \
  --attribute forks_count:integer:default=0

# Blueprint categorization (many-to-many)
mix ash.gen.resource Pactis.Core.BlueprintCategory blueprint_categories

# Stars (user favorites)
  --attribute starred_at:utc_datetime

# Forks (blueprint variations)
mix ash.gen.resource Pactis.Core.Fork forks \
  --attribute forked_at:utc_datetime \
  --attribute changes_description:text

# Downloads/installs tracking
mix ash.gen.resource Pactis.Core.Download downloads \
  --attribute downloaded_at:utc_datetime \
  --attribute ip_address:string \
  --attribute user_agent:string \
  --attribute version:string

# Collections (user-curated blueprint lists)
mix ash.gen.resource Pactis.Core.Collection collections \
  --attribute name:string:required \
  --attribute description:text \
  --attribute visibility:atom:values=public,private:default=public

# Collection items (blueprints in collections)
mix ash.gen.resource Pactis.Core.CollectionItem collection_items \
  --attribute sort_order:integer:default=0 \
  --attribute added_at:utc_datetime

# Reviews/ratings
mix ash.gen.resource Pactis.Core.Review reviews \
  --attribute rating:integer:required \
  --attribute title:string \
  --attribute content:text \
  --attribute helpful_count:integer:default=0

# Issues (bug reports, feature requests)
mix ash.gen.resource Pactis.Core.Issue issues \
  --attribute title:string:required \
  --attribute description:text:required \
  --attribute status:atom:values=open,closed,resolved:default=open \
  --attribute priority:atom:values=low,medium,high:default=medium \
  --attribute issue_type:atom:values=bug,enhancement,question:default=bug

# Note: The legacy generic `Comment` resource has been removed.
# Use domain-specific review comments instead (e.g. `Pactis.Spec.ReviewComment`).

# Changelog entries for blueprints
mix ash.gen.resource Pactis.Core.ChangelogEntry changelog_entries \
  --attribute version:string:required \
  --attribute title:string:required \
  --attribute description:text \
  --attribute breaking_change:boolean:default=false \
  --attribute published_at:utc_datetime

# Generate migrations and migrate
mix ash_postgres.generate_migrations --name create_all_blueprint_registry_resources
mix ash_postgres.migrate

echo "✓ Full blueprint registry created - GitHub for Ash patterns!"
