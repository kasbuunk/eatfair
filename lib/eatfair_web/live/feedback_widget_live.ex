defmodule EatfairWeb.FeedbackWidgetLive do
  @moduledoc """
  Floating feedback widget that captures user feedback with observability metadata.

  This component automatically captures Phoenix request_id, page URL, and version
  information for correlation with logs during troubleshooting.
  """

  use EatfairWeb, :live_component
  alias Eatfair.Feedback

  @impl true
  def update(assigns, socket) do
    changeset = Feedback.change_user_feedback(%{}, assigns[:current_scope])

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))
      |> assign(:show_modal, false)
      |> assign(:request_id, get_request_id(socket))
      |> assign(:page_url, get_page_url(socket))
      |> assign(:version, Eatfair.Version.get())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="feedback-widget">
      <!-- Floating Feedback Button -->
      <div class="fixed bottom-6 right-6 z-40">
        <button
          phx-click="show_feedback_modal"
          phx-target={@myself}
          class="btn btn-primary btn-circle shadow-lg hover:shadow-xl transition-all duration-200"
          aria-label="Provide Feedback"
        >
          <.icon name="hero-chat-bubble-left-right" class="size-6" />
        </button>
      </div>
      
    <!-- Modal -->
      <input type="checkbox" id={"feedback-modal-#{@id}"} class="modal-toggle" checked={@show_modal} />
      <div class="modal" role="dialog">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Share Your Feedback</h3>

          <.form
            for={@form}
            id={"feedback-form-#{@id}"}
            phx-submit="submit_feedback"
            phx-target={@myself}
          >
            <div class="space-y-4">
              <.input
                field={@form[:feedback_type]}
                type="select"
                label="Feedback Type"
                options={[
                  {"Bug Report", "bug_report"},
                  {"Feature Request", "feature_request"},
                  {"General Feedback", "general_feedback"},
                  {"Usability Issue", "usability_issue"}
                ]}
              />

              <.input
                field={@form[:message]}
                type="textarea"
                label="Your Message"
                placeholder="Please describe your feedback in detail..."
                rows="5"
              />
              
    <!-- Hidden metadata fields -->
              <input type="hidden" name="user_feedback[request_id]" value={@request_id} />
              <input type="hidden" name="user_feedback[page_url]" value={@page_url} />
              <input type="hidden" name="user_feedback[version]" value={@version} />
            </div>

            <div class="modal-action">
              <button
                type="button"
                phx-click="hide_feedback_modal"
                phx-target={@myself}
                class="btn btn-ghost"
              >
                Cancel
              </button>
              <button type="submit" class="btn btn-primary">
                Send Feedback
              </button>
            </div>
          </.form>
        </div>
        
    <!-- Modal backdrop -->
        <label
          class="modal-backdrop"
          for={"feedback-modal-#{@id}"}
          phx-click="hide_feedback_modal"
          phx-target={@myself}
        >
          Close
        </label>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("show_feedback_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("hide_feedback_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  def handle_event("submit_feedback", %{"user_feedback" => feedback_params}, socket) do
    metadata = %{
      request_id: socket.assigns.request_id,
      page_url: socket.assigns.page_url,
      version: socket.assigns.version
    }

    case Feedback.create_user_feedback(feedback_params, socket.assigns.current_scope, metadata) do
      {:ok, _feedback} ->
        socket =
          socket
          |> put_flash(:info, "Thank you for your feedback! We'll review it shortly.")
          |> assign(:show_modal, false)
          |> assign(
            :form,
            to_form(Feedback.change_user_feedback(%{}, socket.assigns.current_scope))
          )

        {:noreply, socket}

      {:error, changeset} ->
        socket = assign(socket, :form, to_form(changeset))
        {:noreply, socket}
    end
  end

  # Private helper functions

  defp get_request_id(socket) do
    # Try to get request_id from various sources
    cond do
      get_in(socket.assigns, [:__changed__, :__context__, :request_id]) ->
        socket.assigns.__changed__.__context__.request_id

      socket.assigns[:request_id] ->
        socket.assigns.request_id

      true ->
        # Generate a unique ID as fallback
        "widget-#{System.unique_integer()}"
    end
  end

  defp get_page_url(socket) do
    # Build current page URL from socket context
    case socket.assigns do
      %{uri: %URI{} = uri} ->
        URI.to_string(uri)

      %{__changed__: %{__context__: %{request_path: path}}} ->
        # Fallback: just the path
        path

      _ ->
        # Last resort: try to get from assigns
        socket.assigns[:current_url] || "/unknown"
    end
  end
end
