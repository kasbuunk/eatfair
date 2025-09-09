defmodule EatfairWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use EatfairWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    # Generate unique IDs for all flash elements
    assigns = assign(assigns, :info_flash_id, "#{assigns.id}-info")
    assigns = assign(assigns, :error_flash_id, "#{assigns.id}-error")
    assigns = assign(assigns, :client_error_id, "#{assigns.id}-client-error")
    assigns = assign(assigns, :server_error_id, "#{assigns.id}-server-error")

    ~H"""
    <div id={@id} aria-live="polite">
      <.flash id={@info_flash_id} kind={:info} flash={@flash} />
      <.flash id={@error_flash_id} kind={:error} flash={@flash} />

      <.flash
        id={@client_error_id}
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error ##{@client_error_id}") |> JS.remove_attribute("hidden")}
        phx-connected={hide("##{@client_error_id}") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id={@server_error_id}
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error ##{@server_error_id}") |> JS.remove_attribute("hidden")}
        phx-connected={hide("##{@server_error_id}") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
