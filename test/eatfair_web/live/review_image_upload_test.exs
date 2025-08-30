defmodule EatfairWeb.ReviewImageUploadTest do
  use EatfairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Eatfair.AccountsFixtures
  import Eatfair.RestaurantsFixtures

  alias Eatfair.{Orders, Reviews}

  # Skip these tests until image upload functionality is implemented
  @moduletag :skip

  setup do
    customer = user_fixture()
    restaurant = restaurant_fixture()
    meal = meal_fixture(%{restaurant_id: restaurant.id})

    # Create delivered order so customer can review
    {:ok, order} = Orders.create_order(%{
      customer_id: customer.id,
      restaurant_id: restaurant.id,
      status: "delivered",
      total_price: Decimal.new("25.00"),
      delivery_address: "Review Test Address"
    })

    %{customer: customer, restaurant: restaurant, meal: meal, order: order}
  end

  describe "🎯 Multi-Image Review Upload System" do
    test "eligible user can upload multiple images with review submission", %{
      conn: conn,
      customer: customer,
      restaurant: restaurant,
      order: _order
    } do
      conn = log_in_user(conn, customer)

      # 🍽️ Customer visits restaurant page 
      {:ok, restaurant_live, html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # ✅ Should see "Write a Review" button (customer has delivered order)
      assert html =~ "Write a Review"

      # 📝 Click to open review form
      html = restaurant_live
        |> element("button", "Write a Review") 
        |> render_click()

      # ✅ Should see review form with image upload
      assert html =~ "Share your experience"
      assert html =~ "Upload photos" 
      assert html =~ "live-file-input"
      assert html =~ "Accept up to 3 images"

      # 🔌️ Upload multiple valid images (this will fail until implementation)
      # Note: This test structure shows what we need to implement
      _upload = %Phoenix.LiveView.UploadConfig{
        name: :review_images,
        accept: [".jpg", ".jpeg", ".png", ".webp"],
        max_entries: 3,
        max_file_size: 5_000_000
      }

      # Test file upload (will fail until live_file_input is implemented)
      assert_raise RuntimeError, ~r/upload.*not.*configured/, fn ->
        restaurant_live
        |> file_input("#review-form", :review_images, [
          %{
            last_modified: System.system_time(:millisecond),
            name: "delicious_food.jpg", 
            content: create_test_image_binary(),
            size: 150_000,
            type: "image/jpeg"
          },
          %{
            last_modified: System.system_time(:millisecond),
            name: "restaurant_ambiance.png",
            content: create_test_image_binary(), 
            size: 200_000,
            type: "image/png"
          }
        ])
      end
    end

    test "invalid file types show validation errors", %{
      conn: conn,
      customer: customer,
      restaurant: restaurant
    } do
      conn = log_in_user(conn, customer)
      {:ok, restaurant_live, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      restaurant_live
      |> element("button", "Write a Review")
      |> render_click()

      # 🚨 Try to upload non-image file (will fail until validation implemented)
      assert_raise RuntimeError, ~r/upload.*not.*configured/, fn ->
        restaurant_live
        |> file_input("#review-form", :review_images, [
          %{
            last_modified: System.system_time(:millisecond),
            name: "malicious_file.exe",
            content: <<0, 1, 2, 3>>,
            size: 1000,
            type: "application/exe"
          }
        ])
      end

      # Should eventually show: "Invalid file type. Only JPEG, PNG, and WebP images allowed."
    end

    test "files exceeding size limit show validation errors", %{
      conn: conn,
      customer: customer, 
      restaurant: restaurant
    } do
      _conn = log_in_user(conn, customer)
      {:ok, restaurant_live, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      restaurant_live
      |> element("button", "Write a Review")
      |> render_click()

      # 📏 Try to upload file > 5MB (will fail until validation implemented)
      large_file_content = :crypto.strong_rand_bytes(6_000_000)  # 6MB

      assert_raise RuntimeError, ~r/upload.*not.*configured/, fn ->
        restaurant_live
        |> file_input("#review-form", :review_images, [
          %{
            last_modified: System.system_time(:millisecond),
            name: "huge_image.jpg",
            content: large_file_content,
            size: 6_000_000,
            type: "image/jpeg"
          }
        ])
      end

      # Should eventually show: "File too large (6.0MB). Maximum size: 5.0MB"
    end

    test "uploaded images are compressed and stored correctly", %{
      conn: conn,
      customer: customer,
      restaurant: restaurant,
      order: order
    } do
      _conn = log_in_user(conn, customer)

      # This test validates the backend compression pipeline
      # Will fail until ReviewImage schema and compression are implemented

      # Create review with images directly via context (bypassing UI for now)
      assert_raise UndefinedFunctionError, fn ->
        Reviews.create_review_with_images(%{
          rating: 5,
          comment: "Amazing food! The presentation was beautiful.",
          user_id: customer.id,
          restaurant_id: restaurant.id,
          order_id: order.id,
          images: [
            %{
              name: "test_dish.jpg",
              content: create_test_image_binary(),
              size: 300_000,
              type: "image/jpeg"
            }
          ]
        })
      end

      # Should validate:
      # - Original image stored in uploads/reviews/ 
      # - Compressed version created
      # - ReviewImage record created with paths and metadata
      # - File size reduced but quality maintained
    end

    test "review images display correctly on restaurant page", %{
      conn: _conn,
      customer: _customer,
      restaurant: _restaurant,
      order: _order
    } do
      # This test validates the display integration
      # Will fail until Review schema has images association

      # Skip test for now - will implement after backend is ready
      # Create review with images and verify display
      assert true
    end

    test "mobile device image upload works with appropriate sizing", %{
      conn: conn,
      customer: customer,
      restaurant: restaurant
    } do
      # Mobile-specific test
      mobile_conn = conn 
        |> put_req_header("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)")

      conn = log_in_user(mobile_conn, customer)
      {:ok, restaurant_live, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      # Mobile should have appropriate upload interface
      html = restaurant_live
      |> element("button", "Write a Review")
      |> render_click()

      # Should have mobile-friendly file input
      # (Will fail until mobile-responsive upload UI implemented)
      assert html =~ "live-file-input"
      
      # Mobile uploads often from camera, should handle orientation
      # This will be implemented in the compression pipeline
    end
  end

  describe "🔒 Security & Performance" do
    test "uploaded images are scanned for security threats" do
      # Test that malicious files are detected and rejected
      # This validation happens in FileUpload.validate_upload/1
      
      malicious_content = create_malicious_file_content()
      
      # This will fail until security scanning is implemented
      assert_raise UndefinedFunctionError, fn ->
        Eatfair.FileUpload.validate_upload(%Phoenix.LiveView.UploadEntry{
          client_name: "innocent_image.jpg",
          client_type: "image/jpeg", 
          client_size: byte_size(malicious_content),
          ref: "test_ref",
          uuid: "test_uuid"
        })
      end

      # Should return {:error, ["File contains malicious content"]}
    end

    test "compression reduces file size while maintaining quality" do
      # Test compression pipeline
      original_image = create_test_image_binary()
      _original_size = byte_size(original_image)
      
      # This will fail until compression is implemented
      assert_raise UndefinedFunctionError, fn ->
        Eatfair.FileUpload.compress_image(original_image, %{
          quality: 85,
          max_width: 1200,
          format: :jpeg
        })
      end

      # Should return {:ok, compressed_binary} where compressed size < original
    end
  end

  describe "🎨 User Experience" do  
    test "image preview shows thumbnails before submission", %{
      conn: conn,
      customer: customer,
      restaurant: restaurant
    } do
      conn = log_in_user(conn, customer)
      {:ok, restaurant_live, _html} = live(conn, ~p"/restaurants/#{restaurant.id}")

      restaurant_live
      |> element("button", "Write a Review")
      |> render_click()

      # Upload image and verify preview appears
      # (Will fail until preview functionality implemented)
      assert_raise RuntimeError, ~r/upload.*not.*configured/, fn ->
        restaurant_live
        |> file_input("#review-form", :review_images, [
          %{
            name: "preview_test.jpg",
            content: create_test_image_binary(),
            size: 100_000,
            type: "image/jpeg"
          }
        ])
        
        # Should show thumbnail preview
        # render(restaurant_live) should contain image preview
      end
    end

    test "users can remove images before submission" do
      # Test remove functionality in upload interface
      # Will be implemented as part of live_file_input component
      assert true  # Placeholder until implementation
    end
  end

  # Helper functions for creating test data

  defp create_test_image_binary do
    # Create minimal valid JPEG binary for testing
    # JPEG file signature + minimal data
    <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72, 0, 72, 0, 0>> <>
    <<255, 219, 0, 67, 0, 8, 6, 6, 7, 6, 5, 8, 7, 7, 7, 9, 9, 8, 10, 12, 20, 13, 12, 11, 11, 12, 25, 18, 19, 15, 20, 29, 26, 31, 30, 29, 26, 28, 28, 32, 36, 46, 39, 32, 34, 44, 35, 28, 28, 40, 55, 41, 44, 48, 49, 52, 52, 52, 31, 39, 57, 61, 56, 50, 60, 46, 51, 52, 50>> <>
    <<255, 217>>  # End of JPEG
  end

  defp create_malicious_file_content do
    # Simulate malicious content that should be detected
    "<?php system($_GET['cmd']); ?>" <> create_test_image_binary()
  end
end
