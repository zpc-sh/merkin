defmodule BlueprintForge.Examples.EcommerceProduct do
  @moduledoc """
  Example e-commerce product blueprint demonstrating multi-format generation.

  This blueprint generates a complete product management system with:
  - Phoenix LiveView interface for customer-facing catalog
  - Admin panel for product management
  - REST API for mobile apps and integrations
  - Terminal UI for bulk operations and data management

  Generated features:
  - Product catalog with search and filtering
  - Inventory management
  - Pricing and promotions
  - Category organization
  - Image management
  - Reviews and ratings
  """

  use BlueprintForge.Blueprint

  blueprint do
    name "ecommerce_product"
    description "Complete e-commerce product management system"
    version "1.0.0"
    author "Ash Blueprints Team"
    license "MIT"

    tags ["ecommerce", "product", "catalog", "inventory"]

    # Supported output formats
    formats [:phoenix_html, :admin_panel, :rest_api, :terminal_ui]

    # Dependencies on other blueprints
    dependencies [
      %{name: "user_auth", version: "~> 1.0", optional: false},
      %{name: "file_upload", version: "~> 1.2", optional: true}
    ]

    # Core resource definition
    resource do
      attributes do
        uuid_primary_key :id

        # Basic product information
        attribute :name, :string do
          allow_nil? false
          constraints max_length: 255
          description "Product name displayed to customers"
        end

        attribute :slug, :string do
          allow_nil? false
          constraints [
            match: ~r/^[a-z0-9-]+$/,
            max_length: 255
          ]
          description "URL-friendly product identifier"
        end

        attribute :description, :string do
          description "Detailed product description"
        end

        attribute :short_description, :string do
          constraints max_length: 500
          description "Brief product summary for listings"
        end

        # Pricing and inventory
        attribute :price, :decimal do
          allow_nil? false
          constraints [
            greater_than: 0,
            max: 999999.99
          ]
          description "Current product price"
        end

        attribute :compare_at_price, :decimal do
          constraints [
            greater_than: 0,
            max: 999999.99
          ]
          description "Original price for comparison (crossed out)"
        end

        attribute :cost_price, :decimal do
          constraints [
            greater_than_or_equal_to: 0,
            max: 999999.99
          ]
          description "Cost basis for profit calculations"
          sensitive? true
        end

        attribute :sku, :string do
          allow_nil? false
          constraints max_length: 100
          description "Stock Keeping Unit identifier"
        end

        attribute :barcode, :string do
          constraints max_length: 50
          description "Product barcode (UPC, EAN, etc.)"
        end

        attribute :inventory_quantity, :integer do
          allow_nil? false
          default 0
          constraints min: 0
          description "Current stock quantity"
        end

        attribute :track_inventory, :boolean do
          allow_nil? false
          default true
          description "Whether to track inventory for this product"
        end

        attribute :allow_backorders, :boolean do
          allow_nil? false
          default false
          description "Allow orders when out of stock"
        end

        # Product attributes
        attribute :weight, :decimal do
          constraints min: 0
          description "Product weight in grams"
        end

        attribute :dimensions, :map do
          description "Product dimensions (length, width, height in cm)"
          constraints fields: [
            length: [type: :decimal, min: 0],
            width: [type: :decimal, min: 0],
            height: [type: :decimal, min: 0]
          ]
        end

        attribute :material, :string do
          constraints max_length: 100
          description "Primary material composition"
        end

        attribute :color, :string do
          constraints max_length: 50
          description "Primary product color"
        end

        attribute :size, :string do
          constraints max_length: 20
          description "Product size (S, M, L, XL, etc.)"
        end

        # Status and visibility
        attribute :status, :atom do
          allow_nil? false
          default :draft
          constraints one_of: [:draft, :active, :archived]
          description "Product status in the system"
        end

        attribute :published, :boolean do
          allow_nil? false
          default false
          description "Whether product is visible to customers"
        end

        attribute :featured, :boolean do
          allow_nil? false
          default false
          description "Whether to feature in promotions"
        end

        # SEO and metadata
        attribute :meta_title, :string do
          constraints max_length: 60
          description "SEO title tag"
        end

        attribute :meta_description, :string do
          constraints max_length: 160
          description "SEO meta description"
        end

        attribute :tags, {:array, :string} do
          default []
          description "Product tags for search and filtering"
        end

        # Analytics
        attribute :view_count, :integer do
          allow_nil? false
          default 0
          description "Number of times product was viewed"
        end

        attribute :purchase_count, :integer do
          allow_nil? false
          default 0
          description "Number of times product was purchased"
        end

        # Timestamps
        create_timestamp :inserted_at
        update_timestamp :updated_at
      end

      relationships do
        # Product belongs to a category
        belongs_to :category, BlueprintForge.Examples.ProductCategory do
          allow_nil? false
          description "Product category for organization"
        end

        # Product belongs to a brand/vendor
        belongs_to :vendor, BlueprintForge.Examples.Vendor do
          allow_nil? false
          description "Product vendor or brand"
        end

        # Product has many images
        has_many :images, BlueprintForge.Examples.ProductImage do
          description "Product images for display"
        end

        # Product has many variants (size, color, etc.)
        has_many :variants, BlueprintForge.Examples.ProductVariant do
          description "Product variants with different attributes"
        end

        # Product has many reviews
        has_many :reviews, BlueprintForge.Examples.ProductReview do
          description "Customer reviews and ratings"
        end

        # Many-to-many with collections/wishlists
        many_to_many :collections, BlueprintForge.Examples.Collection do
          through BlueprintForge.Examples.CollectionProduct
          description "Collections this product belongs to"
        end
      end

      # Custom actions beyond basic CRUD
      actions do
        defaults [:create, :read, :update, :destroy]

        # Public actions for customer-facing interface
        read :published do
          filter expr(published == true and status == :active)
          description "Get published products visible to customers"
        end

        read :by_category do
          argument :category_id, :uuid, allow_nil?: false
          filter expr(category_id == ^arg(:category_id) and published == true)
          description "Get published products in a specific category"
        end

        read :search do
          argument :query, :string, allow_nil?: false
          argument :category_id, :uuid
          argument :min_price, :decimal
          argument :max_price, :decimal
          argument :tags, {:array, :string}

          filter expr(
            published == true and
            status == :active and
            (ilike(name, ^("%#{arg(:query)}%")) or
             ilike(description, ^("%#{arg(:query)}%")) or
             ilike(short_description, ^("%#{arg(:query)}%")))
          )

          description "Search products by name, description, and filters"
        end

        read :featured do
          filter expr(featured == true and published == true and status == :active)
          description "Get featured products for promotions"
        end

        read :low_stock do
          argument :threshold, :integer, default: 10
          filter expr(track_inventory == true and inventory_quantity <= ^arg(:threshold))
          description "Get products with low inventory"
        end

        # Admin actions
        update :publish do
          accept []
          change set_attribute(:published, true)
          change set_attribute(:status, :active)
          description "Publish product to make it visible to customers"
        end

        update :unpublish do
          accept []
          change set_attribute(:published, false)
          description "Unpublish product to hide from customers"
        end

        update :adjust_inventory do
          argument :quantity_change, :integer, allow_nil?: false

          change fn changeset, _context ->
            current_quantity = Ash.Changeset.get_attribute(changeset, :inventory_quantity)
            new_quantity = current_quantity + changeset.arguments.quantity_change

            Ash.Changeset.change_attribute(changeset, :inventory_quantity, max(0, new_quantity))
          end

          description "Adjust inventory quantity by specified amount"
        end

        update :increment_view_count do
          accept []
          change increment(:view_count)
          description "Increment product view counter"
        end

        update :increment_purchase_count do
          accept []
          change increment(:purchase_count)
          description "Increment product purchase counter"
        end

        # Bulk operations for admin
        update :bulk_update_status do
          argument :status, :atom, allow_nil?: false
          accept []
          change set_attribute(:status, arg(:status))
          description "Update status for multiple products"
        end

        update :bulk_publish do
          accept []
          change set_attribute(:published, true)
          change set_attribute(:status, :active)
          description "Publish multiple products at once"
        end
      end

      # Validations
      validations do
        validate compare(:price, greater_than: 0), message: "Price must be greater than 0"

        validate compare(:compare_at_price, greater_than: :price),
          where: [compare_at_price: [not_nil: true]],
          message: "Compare at price must be greater than current price"

        validate match(:slug, ~r/^[a-z0-9-]+$/),
          message: "Slug can only contain lowercase letters, numbers, and hyphens"

        validate string_length(:meta_title, max: 60),
          message: "Meta title should be 60 characters or less for SEO"

        validate string_length(:meta_description, max: 160),
          message: "Meta description should be 160 characters or less for SEO"
      end

      # Calculations for derived values
      calculations do
        calculate :discounted?, :boolean, expr(not is_nil(compare_at_price))
        calculate :discount_percentage, :decimal,
          expr(if(not is_nil(compare_at_price),
                  round((compare_at_price - price) / compare_at_price * 100, 2),
                  0))

        calculate :profit_margin, :decimal,
          expr(if(not is_nil(cost_price) and cost_price > 0,
                  round((price - cost_price) / price * 100, 2),
                  0))

        calculate :in_stock?, :boolean,
          expr(not track_inventory or inventory_quantity > 0)

        calculate :can_order?, :boolean,
          expr(status == :active and published and
               (not track_inventory or inventory_quantity > 0 or allow_backorders))

        calculate :average_rating, :decimal do
          # This would be implemented with a custom calculation
          # that aggregates review ratings
        end

        calculate :review_count, :integer do
          # Count of reviews for this product
        end
      end

      # Aggregates for performance
      aggregates do
        count :total_reviews, :reviews
        avg :average_rating, :reviews, :rating
        sum :total_sales, :order_items, :quantity
      end

      # Policies for authorization
      policies do
        # Public read access for published products
        policy action_type(:read) do
          authorize_if expr(published == true and status == :active)
          authorize_if actor_attribute_equals(:role, :admin)
          authorize_if actor_attribute_equals(:role, :vendor) and
                      expr(vendor_id == ^actor(:id))
        end

        # Admin and vendor can create/update
        policy action_type([:create, :update]) do
          authorize_if actor_attribute_equals(:role, :admin)
          authorize_if actor_attribute_equals(:role, :vendor) and
                      expr(vendor_id == ^actor(:id))
        end

        # Only admin can destroy
        policy action_type(:destroy) do
          authorize_if actor_attribute_equals(:role, :admin)
        end
      end
    end

    # Format-specific configurations
    format :phoenix_html do
      description "Customer-facing product catalog with search and filtering"

      features [
        :product_grid,
        :product_detail,
        :search_filters,
        :category_navigation,
        :image_gallery,
        :reviews_display,
        :wishlist_integration
      ]

      themes [:default, :minimal, :dark]

      components [
        :product_card,
        :product_grid,
        :product_detail,
        :search_form,
        :filter_sidebar,
        :price_display,
        :stock_indicator,
        :rating_stars,
        :image_carousel
      ]

      pages [
        :index,        # Product listing with filters
        :show,         # Product detail page
        :search,       # Search results
        :category      # Category-specific listing
      ]

      responsive_breakpoints [:mobile, :tablet, :desktop]
      accessibility_level :aa
    end

    format :admin_panel do
      description "Complete product management interface for administrators"

      features [
        :product_management,
        :inventory_tracking,
        :bulk_operations,
        :analytics_dashboard,
        :category_management,
        :vendor_management,
        :export_import,
        :low_stock_alerts
      ]

      components [
        :product_table,
        :product_form,
        :inventory_widget,
        :analytics_charts,
        :bulk_action_bar,
        :status_badges,
        :price_editor,
        :image_uploader
      ]

      dashboard_widgets [
        :total_products,
        :published_products,
        :low_stock_count,
        :revenue_metrics,
        :top_selling_products,
        :recent_products
      ]

      bulk_operations [
        :update_status,
        :bulk_publish,
        :bulk_unpublish,
        :export_csv,
        :update_prices,
        :adjust_inventory
      ]

      access_roles [:admin, :vendor, :inventory_manager]
    end

    format :rest_api do
      description "RESTful API for mobile apps and third-party integrations"

      endpoints [
        # Public endpoints
        "GET /api/products",           # List published products
        "GET /api/products/search",    # Search products
        "GET /api/products/:id",       # Get product details
        "GET /api/categories/:id/products", # Products by category

        # Admin endpoints
        "POST /api/admin/products",    # Create product
        "PUT /api/admin/products/:id", # Update product
        "DELETE /api/admin/products/:id", # Delete product
        "POST /api/admin/products/:id/publish", # Publish product
        "POST /api/admin/products/:id/inventory", # Adjust inventory

        # Bulk endpoints
        "POST /api/admin/products/bulk/status", # Bulk status update
        "POST /api/admin/products/bulk/publish" # Bulk publish
      ]

      authentication [:bearer_token, :api_key]
      rate_limiting true
      pagination_default 20
      pagination_max 100

      serialization_formats [:json, :json_api]
      api_documentation :openapi_v3

      response_codes [
        200, # Success
        201, # Created
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
      description "Terminal interface for bulk operations and data management"

      features [
        :product_browser,
        :bulk_editor,
        :inventory_dashboard,
        :search_interface,
        :export_tools,
        :quick_actions
      ]

      views [
        :list_view,      # Tabular product listing
        :detail_view,    # Single product details
        :edit_view,      # Product editing form
        :search_view,    # Search interface
        :stats_view      # Analytics and statistics
      ]

      keyboard_shortcuts [
        "n" => :new_product,
        "e" => :edit_product,
        "d" => :delete_product,
        "p" => :toggle_published,
        "s" => :search,
        "f" => :filter,
        "r" => :refresh,
        "q" => :quit,
        "?" => :help
      ]

      themes [:default, :minimal, :high_contrast]
      color_support true
      unicode_support true
    end

    # Installation requirements
    installation do
      dependencies [
        {:decimal, "~> 2.0"},
        {:phoenix_live_view, "~> 0.20"},
        {:ecto, "~> 3.10"}
      ]

      migrations [
        "Create products table",
        "Add product indexes",
        "Create product_images table",
        "Create product_variants table",
        "Create product_reviews table"
      ]

      configuration [
        "Add product routes to router",
        "Configure image upload storage",
        "Set up search indexing",
        "Configure rate limiting for API"
      ]

      post_install_notes """
      1. Run migrations: mix ecto.migrate
      2. Add routes to your router.ex:

         scope "/", MyAppWeb do
           pipe_through :browser
           live "/products", ProductLive.Index, :index
           live "/products/:id", ProductLive.Show, :show
         end

         scope "/admin", MyAppWeb.Admin do
           pipe_through [:browser, :require_admin]
           live "/products", ProductLive.Index, :index
         end

         scope "/api", MyAppWeb.Api do
           pipe_through :api
           resources "/products", ProductController, only: [:index, :show]
         end

      3. Configure image uploads in config/config.exs
      4. Set up search indexing if using full-text search
      5. Configure rate limiting for API endpoints
      """
    end

    # Quality metrics and testing
    quality do
      test_coverage_target 90
      accessibility_level :aa
      performance_budget %{
        generation_time: 2000,  # 2 seconds max
        bundle_size: 150,       # 150KB max
        api_response_time: 200  # 200ms max
      }

      visual_regression_tests [
        :product_grid_responsive,
        :product_detail_mobile,
        :admin_dashboard,
        :search_results
      ]

      accessibility_tests [
        :keyboard_navigation,
        :screen_reader_compatibility,
        :color_contrast,
        :focus_management
      ]
    end
  end
end
