defmodule BlueprintForge.Examples.BlogPlatform do
  @moduledoc """
  Example blog platform blueprint demonstrating multi-format generation.

  This blueprint generates a complete blog management system with:
  - Phoenix LiveView interface for readers and authors
  - Admin panel for content management and moderation
  - REST API for headless CMS usage and mobile apps
  - Terminal UI for bulk content operations and analytics

  Generated features:
  - Article creation and editing with rich text
  - Comment system with moderation
  - User roles (reader, author, editor, admin)
  - Category and tag organization
  - SEO optimization
  - Analytics and statistics
  - Content scheduling and drafts
  """

  use BlueprintForge.Blueprint

  blueprint do
    name "blog_platform"
    description "Complete blog platform with multi-user publishing"
    version "1.0.0"
    author "Ash Blueprints Team"
    license "MIT"

    tags ["blog", "cms", "publishing", "content"]

    # Supported output formats
    formats [:phoenix_html, :admin_panel, :rest_api, :terminal_ui]

    # Dependencies on other blueprints
    dependencies [
      %{name: "user_auth", version: "~> 1.0", optional: false},
      %{name: "rich_text_editor", version: "~> 1.1", optional: true},
      %{name: "comment_system", version: "~> 1.0", optional: true}
    ]

    # Core resource definition
    resource do
      attributes do
        uuid_primary_key :id

        # Basic article information
        attribute :title, :string do
          allow_nil? false
          constraints max_length: 255
          description "Article title displayed to readers"
        end

        attribute :slug, :string do
          allow_nil? false
          constraints [
            match: ~r/^[a-z0-9-]+$/,
            max_length: 255
          ]
          description "URL-friendly article identifier"
        end

        attribute :excerpt, :string do
          constraints max_length: 500
          description "Brief article summary for listings and SEO"
        end

        attribute :content, :string do
          allow_nil? false
          description "Full article content in markdown or HTML"
        end

        attribute :content_format, :atom do
          allow_nil? false
          default :markdown
          constraints one_of: [:markdown, :html, :rich_text]
          description "Format of the content field"
        end

        # Publishing and status
        attribute :status, :atom do
          allow_nil? false
          default :draft
          constraints one_of: [:draft, :published, :scheduled, :archived]
          description "Article publication status"
        end

        attribute :published, :boolean do
          allow_nil? false
          default false
          description "Whether article is visible to readers"
        end

        attribute :published_at, :utc_datetime do
          description "When the article was published"
        end

        attribute :scheduled_for, :utc_datetime do
          description "When to automatically publish a scheduled article"
        end

        attribute :featured, :boolean do
          allow_nil? false
          default false
          description "Whether to feature on homepage"
        end

        attribute :sticky, :boolean do
          allow_nil? false
          default false
          description "Pin article to top of listings"
        end

        # Content organization
        attribute :tags, {:array, :string} do
          default []
          description "Article tags for organization and discovery"
        end

        # SEO and metadata
        attribute :meta_title, :string do
          constraints max_length: 60
          description "SEO title tag (defaults to article title)"
        end

        attribute :meta_description, :string do
          constraints max_length: 160
          description "SEO meta description (defaults to excerpt)"
        end

        attribute :canonical_url, :string do
          constraints max_length: 500
          description "Canonical URL for SEO (if republished content)"
        end

        # Reading and engagement
        attribute :reading_time_minutes, :integer do
          constraints min: 1
          description "Estimated reading time in minutes"
        end

        attribute :view_count, :integer do
          allow_nil? false
          default 0
          description "Number of times article was viewed"
        end

        attribute :like_count, :integer do
          allow_nil? false
          default 0
          description "Number of likes received"
        end

        attribute :share_count, :integer do
          allow_nil? false
          default 0
          description "Number of times article was shared"
        end

        # Content settings
        attribute :allow_comments, :boolean do
          allow_nil? false
          default true
          description "Whether to allow comments on this article"
        end

        attribute :require_comment_approval, :boolean do
          allow_nil? false
          default false
          description "Whether comments require approval"
        end

        attribute :newsletter_featured, :boolean do
          allow_nil? false
          default false
          description "Include in newsletter digest"
        end

        # Featured image
        attribute :featured_image_url, :string do
          constraints max_length: 500
          description "URL of the featured image"
        end

        attribute :featured_image_alt, :string do
          constraints max_length: 255
          description "Alt text for featured image (accessibility)"
        end

        attribute :featured_image_caption, :string do
          constraints max_length: 255
          description "Caption for featured image"
        end

        # Social media
        attribute :social_title, :string do
          constraints max_length: 70
          description "Title for social media sharing (og:title)"
        end

        attribute :social_description, :string do
          constraints max_length: 200
          description "Description for social media sharing (og:description)"
        end

        attribute :social_image_url, :string do
          constraints max_length: 500
          description "Image for social media sharing (og:image)"
        end

        # Analytics and performance
        attribute :bounce_rate, :decimal do
          constraints [min: 0, max: 100]
          description "Percentage of single-page sessions"
        end

        attribute :average_time_on_page, :integer do
          constraints min: 0
          description "Average time spent reading in seconds"
        end

        attribute :conversion_rate, :decimal do
          constraints [min: 0, max: 100]
          description "Percentage of readers who took desired action"
        end

        # Timestamps
        create_timestamp :inserted_at
        update_timestamp :updated_at
      end

      relationships do
        # Article belongs to an author
        belongs_to :author, BlueprintForge.Examples.User do
          allow_nil? false
          description "User who wrote the article"
        end

        # Article belongs to a category
        belongs_to :category, BlueprintForge.Examples.BlogCategory do
          allow_nil? false
          description "Primary category for organization"
        end

        # Article can have an editor (different from author)
        belongs_to :editor, BlueprintForge.Examples.User do
          description "User who last edited the article"
        end

        # Article has many comments
        has_many :comments, BlueprintForge.Examples.ArticleComment do
          description "Reader comments on the article"
        end

        # Article has many likes
        has_many :likes, BlueprintForge.Examples.ArticleLike do
          description "User likes for the article"
        end

        # Article has many shares
        has_many :shares, BlueprintForge.Examples.ArticleShare do
          description "Social media shares of the article"
        end

        # Article has many revisions (version history)
        has_many :revisions, BlueprintForge.Examples.ArticleRevision do
          description "Edit history and version control"
        end

        # Many-to-many with related articles
        many_to_many :related_articles, __MODULE__ do
          through BlueprintForge.Examples.RelatedArticle
          description "Articles related to this one"
        end

        # Many-to-many with article series
        many_to_many :series, BlueprintForge.Examples.ArticleSeries do
          through BlueprintForge.Examples.SeriesArticle
          description "Article series this belongs to"
        end
      end

      # Custom actions beyond basic CRUD
      actions do
        defaults [:create, :read, :update, :destroy]

        # Public actions for readers
        read :published do
          filter expr(published == true and status == :published)
          prepare build(sort: [inserted_at: :desc])
          description "Get published articles visible to readers"
        end

        read :by_author do
          argument :author_id, :uuid, allow_nil?: false
          filter expr(author_id == ^arg(:author_id) and published == true)
          prepare build(sort: [published_at: :desc])
          description "Get published articles by specific author"
        end

        read :by_category do
          argument :category_id, :uuid, allow_nil?: false
          filter expr(category_id == ^arg(:category_id) and published == true)
          prepare build(sort: [published_at: :desc])
          description "Get published articles in specific category"
        end

        read :by_tag do
          argument :tag, :string, allow_nil?: false
          filter expr(^arg(:tag) in tags and published == true)
          prepare build(sort: [published_at: :desc])
          description "Get published articles with specific tag"
        end

        read :search do
          argument :query, :string, allow_nil?: false
          argument :category_id, :uuid
          argument :author_id, :uuid
          argument :tags, {:array, :string}

          filter expr(
            published == true and
            status == :published and
            (ilike(title, ^("%#{arg(:query)}%")) or
             ilike(excerpt, ^("%#{arg(:query)}%")) or
             ilike(content, ^("%#{arg(:query)}%")))
          )

          description "Search published articles by content"
        end

        read :featured do
          filter expr(featured == true and published == true and status == :published)
          prepare build(sort: [published_at: :desc])
          description "Get featured articles for homepage"
        end

        read :popular do
          prepare build(sort: [view_count: :desc, like_count: :desc])
          filter expr(published == true and status == :published)
          description "Get popular articles by engagement"
        end

        read :recent do
          argument :days, :integer, default: 7

          filter expr(
            published == true and
            status == :published and
            published_at > ago(^arg(:days), :day)
          )

          prepare build(sort: [published_at: :desc])
          description "Get recently published articles"
        end

        # Author/Editor actions
        read :drafts do
          filter expr(author_id == ^actor(:id) and status == :draft)
          prepare build(sort: [updated_at: :desc])
          description "Get author's draft articles"
        end

        read :scheduled do
          filter expr(
            (author_id == ^actor(:id) or ^actor(:role) in [:editor, :admin]) and
            status == :scheduled
          )
          prepare build(sort: [scheduled_for: :asc])
          description "Get scheduled articles"
        end

        # Publishing workflow
        update :publish do
          accept []

          change fn changeset, _context ->
            now = DateTime.utc_now()

            changeset
            |> Ash.Changeset.change_attribute(:status, :published)
            |> Ash.Changeset.change_attribute(:published, true)
            |> Ash.Changeset.change_attribute(:published_at, now)
          end

          description "Publish article immediately"
        end

        update :unpublish do
          accept []
          change set_attribute(:published, false)
          change set_attribute(:status, :draft)
          description "Unpublish article and return to draft"
        end

        update :schedule do
          argument :scheduled_for, :utc_datetime, allow_nil?: false

          accept []
          change set_attribute(:status, :scheduled)
          change set_attribute(:scheduled_for, arg(:scheduled_for))
          description "Schedule article for future publication"
        end

        update :archive do
          accept []
          change set_attribute(:status, :archived)
          change set_attribute(:published, false)
          description "Archive article (remove from public view)"
        end

        # Engagement actions
        update :increment_view_count do
          accept []
          change increment(:view_count)
          description "Increment article view counter"
        end

        update :increment_like_count do
          accept []
          change increment(:like_count)
          description "Increment article like counter"
        end

        update :increment_share_count do
          accept []
          change increment(:share_count)
          description "Increment article share counter"
        end

        # SEO and content optimization
        update :auto_generate_seo do
          accept []

          change fn changeset, _context ->
            title = Ash.Changeset.get_attribute(changeset, :title)
            excerpt = Ash.Changeset.get_attribute(changeset, :excerpt)

            changeset
            |> Ash.Changeset.change_attribute(:meta_title, String.slice(title || "", 0, 60))
            |> Ash.Changeset.change_attribute(:meta_description, String.slice(excerpt || "", 0, 160))
          end

          description "Auto-generate SEO metadata from title and excerpt"
        end

        update :calculate_reading_time do
          accept []

          change fn changeset, _context ->
            content = Ash.Changeset.get_attribute(changeset, :content)
            word_count = content |> String.split() |> length()
            reading_time = max(1, div(word_count, 200)) # Assume 200 WPM

            Ash.Changeset.change_attribute(changeset, :reading_time_minutes, reading_time)
          end

          description "Calculate estimated reading time from content"
        end

        # Bulk operations for admin
        update :bulk_publish do
          accept []
          change set_attribute(:published, true)
          change set_attribute(:status, :published)
          change set_attribute(:published_at, DateTime.utc_now())
          description "Bulk publish multiple articles"
        end

        update :bulk_archive do
          accept []
          change set_attribute(:status, :archived)
          change set_attribute(:published, false)
          description "Bulk archive multiple articles"
        end

        update :bulk_update_category do
          argument :category_id, :uuid, allow_nil?: false
          accept []
          change set_attribute(:category_id, arg(:category_id))
          description "Bulk update category for multiple articles"
        end
      end

      # Validations
      validations do
        validate match(:slug, ~r/^[a-z0-9-]+$/),
          message: "Slug can only contain lowercase letters, numbers, and hyphens"

        validate string_length(:title, min: 5, max: 255),
          message: "Title must be between 5 and 255 characters"

        validate string_length(:content, min: 100),
          message: "Content must be at least 100 characters",
          where: [status: [:published, :scheduled]]

        validate string_length(:meta_title, max: 60),
          message: "Meta title should be 60 characters or less for SEO"

        validate string_length(:meta_description, max: 160),
          message: "Meta description should be 160 characters or less for SEO"

        validate present([:excerpt]),
          message: "Excerpt is required for published articles",
          where: [status: [:published, :scheduled]]

        validate present([:featured_image_url]),
          message: "Featured image is required for featured articles",
          where: [featured: true]

        validate compare(:scheduled_for, greater_than: &DateTime.utc_now/0),
          message: "Scheduled date must be in the future",
          where: [status: :scheduled]
      end

      # Calculations for derived values
      calculations do
        calculate :is_published?, :boolean, expr(published == true and status == :published)

        calculate :is_scheduled?, :boolean,
          expr(status == :scheduled and scheduled_for > ^DateTime.utc_now())

        calculate :is_overdue?, :boolean,
          expr(status == :scheduled and scheduled_for <= ^DateTime.utc_now())

        calculate :engagement_score, :decimal do
          # Composite score based on views, likes, comments, shares
          expr((view_count * 0.1) + (like_count * 2) + (comment_count * 3) + (share_count * 5))
        end

        calculate :seo_score, :decimal do
          # SEO completeness score based on metadata presence
          expr(
            (if(not is_nil(meta_title), 25, 0)) +
            (if(not is_nil(meta_description), 25, 0)) +
            (if(not is_nil(featured_image_url), 25, 0)) +
            (if(length(tags) > 0, 25, 0))
          )
        end

        calculate :content_quality_score, :decimal do
          # Content quality based on length, structure, etc.
          expr(
            (if(string_length(content) > 1000, 30, 0)) +
            (if(string_length(excerpt) > 100, 20, 0)) +
            (if(not is_nil(featured_image_url), 25, 0)) +
            (if(length(tags) >= 3, 25, 0))
          )
        end

        calculate :days_since_published, :integer,
          expr(date_diff(^Date.utc_today(), published_at, :day))

        calculate :estimated_revenue, :decimal do
          # Estimated revenue based on views and conversion rate
          expr((view_count * conversion_rate / 100) * 0.05) # $0.05 per conversion
        end
      end

      # Aggregates for performance
      aggregates do
        count :comment_count, :comments
        count :approved_comment_count, :comments, query: [filter: expr(approved == true)]
        count :like_count_aggregate, :likes
        count :share_count_aggregate, :shares
        avg :average_rating, :comments, :rating
      end

      # Policies for authorization
      policies do
        # Public read access for published articles
        policy action_type(:read) do
          authorize_if expr(published == true and status == :published)
          authorize_if actor_attribute_equals(:role, :admin)
          authorize_if actor_attribute_equals(:role, :editor)
          authorize_if expr(author_id == ^actor(:id))
        end

        # Authors can create articles
        policy action_type(:create) do
          authorize_if actor_attribute_equals(:role, :author)
          authorize_if actor_attribute_equals(:role, :editor)
          authorize_if actor_attribute_equals(:role, :admin)
        end

        # Authors can update their own articles, editors and admins can update any
        policy action_type(:update) do
          authorize_if actor_attribute_equals(:role, :admin)
          authorize_if actor_attribute_equals(:role, :editor)
          authorize_if expr(author_id == ^actor(:id))
        end

        # Only admin can destroy articles
        policy action_type(:destroy) do
          authorize_if actor_attribute_equals(:role, :admin)
        end

        # Publishing requires editor or admin role
        policy action([:publish, :schedule]) do
          authorize_if actor_attribute_equals(:role, :admin)
          authorize_if actor_attribute_equals(:role, :editor)
          authorize_if expr(author_id == ^actor(:id) and ^actor(:can_publish?) == true)
        end
      end
    end

    # Format-specific configurations
    format :phoenix_html do
      description "Reader-facing blog interface with rich reading experience"

      features [
        :article_listing,
        :article_reader,
        :author_pages,
        :category_pages,
        :tag_navigation,
        :search_functionality,
        :comment_system,
        :social_sharing,
        :newsletter_signup,
        :related_articles
      ]

      themes [:default, :minimal, :dark, :serif]

      components [
        :article_card,
        :article_grid,
        :article_reader,
        :author_bio,
        :category_nav,
        :tag_cloud,
        :search_form,
        :comment_section,
        :share_buttons,
        :reading_progress,
        :related_articles,
        :newsletter_form
      ]

      pages [
        :index,          # Homepage with featured and recent articles
        :article,        # Individual article reading page
        :author,         # Author profile and articles
        :category,       # Category listing page
        :tag,            # Tag-based article listing
        :search,         # Search results page
        :archive         # Date-based archive
      ]

      responsive_breakpoints [:mobile, :tablet, :desktop]
      accessibility_level :aa
      seo_optimization true
      analytics_integration [:google_analytics, :plausible]
    end

    format :admin_panel do
      description "Complete content management system for authors and editors"

      features [
        :article_management,
        :draft_workflow,
        :publishing_scheduler,
        :comment_moderation,
        :analytics_dashboard,
        :author_management,
        :category_management,
        :bulk_operations,
        :seo_optimization,
        :content_calendar
      ]

      components [
        :article_table,
        :rich_text_editor,
        :publishing_workflow,
        :comment_moderation_queue,
        :analytics_charts,
        :content_calendar,
        :bulk_action_bar,
        :seo_optimizer,
        :media_library,
        :author_dashboard
      ]

      dashboard_widgets [
        :total_articles,
        :published_articles,
        :draft_count,
        :pending_comments,
        :total_views,
        :engagement_metrics,
        :top_performing_articles,
        :recent_activity,
        :scheduled_posts,
        :seo_health_score
      ]

      workflows [
        :draft_to_review,
        :review_to_published,
        :schedule_publication,
        :archive_workflow,
        :comment_approval
      ]

      bulk_operations [
        :bulk_publish,
        :bulk_archive,
        :bulk_category_update,
        :bulk_tag_update,
        :bulk_author_change,
        :bulk_export
      ]

      access_roles [:author, :editor, :admin, :moderator]
    end

    format :rest_api do
      description "Headless CMS API for mobile apps and third-party integrations"

      endpoints [
        # Public endpoints
        "GET /api/articles",              # List published articles
        "GET /api/articles/featured",     # Featured articles
        "GET /api/articles/popular",      # Popular articles
        "GET /api/articles/recent",       # Recent articles
        "GET /api/articles/search",       # Search articles
        "GET /api/articles/:id",          # Get article details
        "GET /api/authors/:id/articles",  # Articles by author
        "GET /api/categories/:id/articles", # Articles by category
        "GET /api/tags/:tag/articles",    # Articles by tag

        # Reader interaction
        "POST /api/articles/:id/like",   # Like article
        "DELETE /api/articles/:id/like", # Unlike article
        "POST /api/articles/:id/share",  # Record share
        "POST /api/articles/:id/view",   # Record view

        # Author endpoints
        "GET /api/author/articles",      # Author's articles
        "GET /api/author/drafts",        # Author's drafts
        "POST /api/author/articles",     # Create article
        "PUT /api/author/articles/:id",  # Update article
        "DELETE /api/author/articles/:id", # Delete article

        # Publishing workflow
        "POST /api/author/articles/:id/publish", # Publish article
        "POST /api/author/articles/:id/schedule", # Schedule article
        "POST /api/author/articles/:id/unpublish", # Unpublish article

        # Admin endpoints
        "GET /api/admin/articles",       # All articles (admin view)
        "POST /api/admin/articles/bulk/publish", # Bulk publish
        "POST /api/admin/articles/bulk/archive", # Bulk archive
        "GET /api/admin/analytics",      # Analytics data
        "GET /api/admin/comments/pending", # Pending comments
      ]

      authentication [:bearer_token, :api_key, :session]
      rate_limiting true
      pagination_default 20
      pagination_max 100

      serialization_formats [:json, :json_api]
      api_documentation :openapi_v3
      versioning_strategy :header # API version via Accept header

      caching [
        articles: "1 hour",
        author_articles: "30 minutes",
        categories: "4 hours",
        popular_articles: "2 hours"
      ]

      response_codes [
        200, # Success
        201, # Created
        204, # No Content
        400, # Bad Request
        401, # Unauthorized
        403, # Forbidden
        404, # Not Found
        422, # Unprocessable Entity
        429, # Too Many Requests
        500  # Internal Server Error
      ]
    end

    format :terminal_ui do
      description "Terminal interface for writers and content managers"

      features [
        :article_browser,
        :writing_interface,
        :publishing_tools,
        :analytics_viewer,
        :bulk_operations,
        :search_interface,
        :comment_moderation,
        :workflow_management
      ]

      views [
        :list_view,       # Article listing with filters
        :editor_view,     # Full-screen article editor
        :preview_view,    # Article preview
        :analytics_view,  # Charts and statistics
        :calendar_view,   # Publishing calendar
        :comments_view,   # Comment moderation
        :search_view      # Search and filtering
      ]

      editor_features [
        :markdown_editing,
        :syntax_highlighting,
        :word_count,
        :spell_check,
        :autosave,
        :distraction_free_mode,
        :split_preview
      ]

      keyboard_shortcuts [
        "n" => :new_article,
        "e" => :edit_article,
        "p" => :publish_article,
        "d" => :delete_article,
        "s" => :save_draft,
        "S" => :schedule_article,
        "v" => :preview_article,
        "c" => :view_comments,
        "a" => :analytics,
        "f" => :search,
        "F" => :filter,
        "r" => :refresh,
        "?" => :help,
        "q" => :quit,
        "Ctrl+S" => :save,
        "Ctrl+P" => :publish,
        "Ctrl+F" => :find_in_content
      ]

      themes [:default, :dark, :high_contrast, :writer_focused]
      distraction_free_mode true
      vim_key_bindings true
      unicode_support true
    end

    # Installation requirements
    installation do
      dependencies [
        {:phoenix_live_view, "~> 0.20"},
        {:earmark, "~> 1.4"}, # Markdown processing
        {:html_sanitize_ex, "~> 1.4"}, # HTML sanitization
        {:ecto, "~> 3.10"},
        {:jason, "~> 1.4"}
      ]

      optional_dependencies [
        {:ex_aws, "~> 2.4"}, # For S3 image uploads
        {:image, "~> 0.37"}, # Image processing
        {:floki, "~> 0.34"}, # HTML parsing for SEO
        {:quantum, "~> 3.5"} # For scheduled publishing
      ]

      migrations [
        "Create blog_articles table",
        "Create blog_categories table",
        "Create article_comments table",
        "Create article_likes table",
        "Create article_shares table",
        "Create article_revisions table",
        "Create article_series table",
        "Add article indexes for performance",
        "Add full-text search indexes"
      ]

      configuration [
        "Add blog routes to router",
        "Configure markdown processor",
        "Set up image upload storage",
        "Configure scheduled job processor",
        "Set up search indexing",
        "Configure social media integration",
        "Set up analytics tracking"
      ]

      post_install_notes """
      🎉 Blog Platform installed successfully!

      Next steps:
      1. Run migrations: mix ecto.migrate

      2. Add routes to your router.ex:
         scope "/", MyAppWeb do
           pipe_through :browser
           live "/blog", BlogLive.Index, :index
           live "/blog/:slug", BlogLive.Show, :show
           live "/authors/:id", AuthorLive.Show, :show
           live "/categories/:slug", CategoryLive.Show, :show
         end

         scope "/admin", MyAppWeb.Admin do
           pipe_through [:browser, :require_auth, :require_author]
           live "/articles", ArticleLive.Index, :index
           live "/articles/new", ArticleLive.Index, :new
           live "/articles/:id/edit", ArticleLive.Index, :edit
           live "/dashboard", DashboardLive, :index
         end

      3. Configure scheduled publishing (optional):
         # config/config.exs
         config :my_app, MyApp.Scheduler,
           jobs: [
             {"* * * * *", {MyApp.Blog, :publish_scheduled_articles, []}}
           ]

      4. Set up image uploads (optional):
         # config/config.exs
         config :ex_aws,
           access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
           secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
           region: System.get_env("AWS_REGION", "us-east-1")

      5. Configure search (optional):
         Consider adding full-text search with PostgreSQL or Elasticsearch

      6. Test the installation:
         - Visit /admin/articles to start writing
         - Visit /blog to see the public blog
         - Create your first article and publish it

      Happy blogging! ✍️
      """
    end

    # Quality metrics and testing
    quality do
      test_coverage_target 85
      accessibility_level :aa
      performance_budget %{
        generation_time: 3000,    # 3 seconds max for complex blog
        page_load_time: 2000,     # 2 seconds for article pages
        admin_response_time: 500, # 500ms for admin actions
        api_response_time: 200,   # 200ms for API endpoints
        bundle_size: 200          # 200KB max bundle
      }

      visual_regression_tests [
        :article_listing_responsive,
        :article_reader_mobile,
        :admin_editor_interface,
        :comment_system,
        :author_page_layout
      ]

      accessibility_tests [
        :keyboard_navigation_blog,
        :screen_reader_articles,
        :color_contrast_all_themes,
        :focus_management_editor,
        :aria_labels_content
      ]

      seo_tests [
        :meta_tags_generation,
        :structured_data,
        :canonical_urls,
        :sitemap_generation,
        :social_media_tags
      ]

      performance_tests [
        :article_load_speed,
        :search_response_time,
        :admin_dashboard_load,
        :bulk_operations_performance,
        :database_query_optimization
      ]
    end
  end
end
