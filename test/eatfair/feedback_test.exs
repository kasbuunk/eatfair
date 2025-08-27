defmodule Eatfair.FeedbackTest do
  @moduledoc """
  Test suite for the feedback context functionality.
  
  This test focuses on the core business logic for user feedback management,
  request correlation, version tracking, and admin operations.
  """
  
  use Eatfair.DataCase

  alias Eatfair.Feedback
  alias Eatfair.Accounts
  
  describe "user feedback" do
    test "creates feedback with all required fields" do
      {:ok, user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "hello world!"
      })
      
      feedback_params = %{
        feedback_type: "bug_report",
        message: "This is a detailed bug report about the search functionality"
      }
      
      user_scope = %{user: user}
      metadata = %{
        request_id: "req-123",
        page_url: "/restaurants",
        version: "0.1.0"
      }
      
      {:ok, feedback} = Feedback.create_user_feedback(feedback_params, user_scope, metadata)
      
      assert feedback.feedback_type == "bug_report"
      assert feedback.message == "This is a detailed bug report about the search functionality"
      assert feedback.user_id == user.id
      assert feedback.request_id == "req-123"
      assert feedback.page_url == "/restaurants"
      assert feedback.version == "0.1.0"
      assert feedback.status == "new"
      assert feedback.inserted_at != nil
    end
    
    test "validates feedback_type is valid" do
      {:ok, user} = Accounts.register_user(%{
        email: "test2@example.com", 
        password: "hello world!"
      })
      
      feedback_params = %{
        feedback_type: "invalid_type",
        message: "This should fail validation"
      }
      
      {:error, changeset} = Feedback.create_user_feedback(feedback_params, %{user: user}, %{})
      
      assert changeset.errors[:feedback_type] != nil
    end
    
    test "validates message is minimum length" do
      {:ok, user} = Accounts.register_user(%{
        email: "test3@example.com",
        password: "hello world!"
      })
      
      feedback_params = %{
        feedback_type: "bug_report",
        message: "Short"
      }
      
      {:error, changeset} = Feedback.create_user_feedback(feedback_params, %{user: user}, %{})
      
      assert changeset.errors[:message] != nil
    end
    
    test "lists user feedback" do
      {:ok, user1} = Accounts.register_user(%{
        email: "test4@example.com",
        password: "hello world!"
      })
      
      {:ok, user2} = Accounts.register_user(%{
        email: "test5@example.com", 
        password: "hello world!"
      })
      
      # Create feedback for both users
      {:ok, _feedback1} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "First user feedback"},
        %{user: user1}, 
        %{request_id: "req-1", version: "0.1.0"}
      )
      
      {:ok, _feedback2} = Feedback.create_user_feedback(
        %{feedback_type: "feature_request", message: "Second user feedback"},
        %{user: user2},
        %{request_id: "req-2", version: "0.1.0"}
      )
      
      feedback_list = Feedback.list_user_feedback()
      assert length(feedback_list) == 2
    end
    
    test "gets feedback by request_id" do
      {:ok, user} = Accounts.register_user(%{
        email: "test6@example.com",
        password: "hello world!"
      })
      
      request_id = "specific-req-123"
      
      {:ok, feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "Feedback for specific request"},
        %{user: user},
        %{request_id: request_id, version: "0.1.0"}
      )
      
      # Create another feedback with different request_id
      {:ok, _other_feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "Different request feedback"},
        %{user: user},
        %{request_id: "different-req", version: "0.1.0"}
      )
      
      result = Feedback.get_feedback_by_request_id(request_id)
      
      assert length(result) == 1
      assert hd(result).id == feedback.id
    end
  end
  
  describe "admin operations" do
    test "updates feedback status" do
      {:ok, user} = Accounts.register_user(%{
        email: "admin_test@example.com",
        password: "hello world!"
      })
      
      {:ok, feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "Feedback to be updated"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      assert feedback.status == "new"
      
      {:ok, updated_feedback} = Feedback.update_feedback_status(feedback, %{
        status: "in_progress",
        admin_notes: "Looking into this issue"
      })
      
      assert updated_feedback.status == "in_progress"
      assert updated_feedback.admin_notes == "Looking into this issue"
    end
    
    test "gets feedback statistics" do
      {:ok, user} = Accounts.register_user(%{
        email: "stats_test@example.com",
        password: "hello world!"
      })
      
      # Create feedback with different statuses
      {:ok, _new_feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "New feedback item"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      {:ok, in_progress_feedback} = Feedback.create_user_feedback(
        %{feedback_type: "feature_request", message: "In progress feedback"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      {:ok, resolved_feedback} = Feedback.create_user_feedback(
        %{feedback_type: "usability_issue", message: "Resolved feedback"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      # Update statuses
      Feedback.update_feedback_status(in_progress_feedback, %{status: "in_progress"})
      Feedback.update_feedback_status(resolved_feedback, %{status: "resolved"})
      
      stats = Feedback.get_feedback_stats()
      
      assert stats.total >= 3  # At least the 3 we created
      assert stats.new >= 1    # At least the new one
      assert stats.in_progress >= 1
      assert stats.resolved >= 1
    end
  end
  
  describe "version tracking" do
    test "Version.get/0 returns current version" do
      version = Eatfair.Version.get()
      assert is_binary(version)
      assert version != ""
    end
    
    test "Version.inject_logger_metadata/0 adds version to logger context" do
      Eatfair.Version.inject_logger_metadata()
      metadata = Logger.metadata()
      
      # Check that version was added to metadata
      version_metadata = Keyword.get(metadata, :version)
      assert version_metadata != nil
      assert is_binary(version_metadata)
    end
    
    test "Version.telemetry_metadata/0 returns version map" do
      metadata = Eatfair.Version.telemetry_metadata()
      
      assert is_map(metadata)
      assert metadata.version != nil
      assert is_binary(metadata.version)
    end
  end
  
  describe "pubsub broadcasts" do
    test "feedback creation broadcasts to admin channel" do
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "admin:feedback")
      
      {:ok, user} = Accounts.register_user(%{
        email: "pubsub_test@example.com",
        password: "hello world!"
      })
      
      {:ok, feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "PubSub broadcast test"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      # Should receive broadcast message
      assert_receive {:new_feedback, received_feedback}, 1000
      assert received_feedback.id == feedback.id
      assert received_feedback.message == "PubSub broadcast test"
    end
    
    test "status updates broadcast to admin channel" do
      Phoenix.PubSub.subscribe(Eatfair.PubSub, "admin:feedback")
      
      {:ok, user} = Accounts.register_user(%{
        email: "status_pubsub_test@example.com",
        password: "hello world!"
      })
      
      {:ok, feedback} = Feedback.create_user_feedback(
        %{feedback_type: "bug_report", message: "Status update test"},
        %{user: user},
        %{version: "0.1.0"}
      )
      
      # Clear the creation broadcast
      assert_receive {:new_feedback, _}, 1000
      
      {:ok, updated_feedback} = Feedback.update_feedback_status(feedback, %{
        status: "in_progress"
      })
      
      # Should receive status update broadcast
      assert_receive {:feedback_updated, received_feedback}, 1000
      assert received_feedback.id == updated_feedback.id
      assert received_feedback.status == "in_progress"
    end
  end
end
