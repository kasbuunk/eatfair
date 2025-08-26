defmodule EatfairWeb.Live.Components.AddressAutocomplete do
  use EatfairWeb, :live_component

  alias Eatfair.AddressAutocomplete

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:suggestions, [])
     |> assign(:show_suggestions, false)
     |> assign(:query, "")
     |> assign(:selected_index, -1)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:value, fn -> "" end)
     |> assign_new(:placeholder, fn -> "Enter your address..." end)
     |> assign_new(:class, fn -> "" end)
     |> assign_new(:target, fn -> nil end)
     |> assign_new(:event, fn -> "address_selected" end)
     |> assign(:query, assigns[:value] || "")}  # Use the value prop to initialize query
  end

  @impl true
  def handle_event("input_change", %{"value" => query}, socket) do
    suggestions = 
      if String.length(String.trim(query)) >= 2 do
        AddressAutocomplete.suggest_addresses(query)
        |> Enum.take(8)  # Limit to 8 suggestions for UX
      else
        []
      end

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:suggestions, suggestions)
     |> assign(:show_suggestions, length(suggestions) > 0)
     |> assign(:selected_index, -1)}
  end

  @impl true
  def handle_event("select_suggestion", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    
    case Enum.at(socket.assigns.suggestions, index) do
      nil -> 
        {:noreply, socket}
      
      suggestion ->
        selected_address = suggestion.display
        
        # Send event to parent component
        if socket.assigns.target do
          send_update(socket.assigns.target, 
            id: socket.assigns.target, 
            address_selected: selected_address
          )
        else
          send(self(), {socket.assigns.event, selected_address})
        end
        
        {:noreply,
         socket
         |> assign(:query, selected_address)
         |> assign(:show_suggestions, false)
         |> assign(:selected_index, -1)}
    end
  end

  @impl true
  def handle_event("keyboard_navigation", %{"key" => "ArrowDown"}, socket) do
    max_index = length(socket.assigns.suggestions) - 1
    new_index = min(socket.assigns.selected_index + 1, max_index)
    
    {:noreply, assign(socket, :selected_index, new_index)}
  end

  @impl true 
  def handle_event("keyboard_navigation", %{"key" => "ArrowUp"}, socket) do
    new_index = max(socket.assigns.selected_index - 1, -1)
    
    {:noreply, assign(socket, :selected_index, new_index)}
  end

  @impl true
  def handle_event("keyboard_navigation", %{"key" => "Enter"}, socket) do
    if socket.assigns.selected_index >= 0 do
      handle_event("select_suggestion", %{"index" => to_string(socket.assigns.selected_index)}, socket)
    else
      # If no suggestion selected, submit current query as-is
      selected_address = socket.assigns.query
      
      # Send event to parent component
      if socket.assigns.target do
        send_update(socket.assigns.target, 
          id: socket.assigns.target, 
          address_selected: selected_address
        )
      else
        send(self(), {socket.assigns.event, selected_address})
      end
      
      {:noreply, assign(socket, :show_suggestions, false)}
    end
  end

  @impl true
  def handle_event("keyboard_navigation", %{"key" => "Tab"}, socket) do
    # Tab should autocomplete the first suggestion if available
    if socket.assigns.selected_index >= 0 do
      handle_event("select_suggestion", %{"index" => to_string(socket.assigns.selected_index)}, socket)
    else
      # Auto-select first suggestion if available
      case socket.assigns.suggestions do
        [_first_suggestion | _] ->
          handle_event("select_suggestion", %{"index" => "0"}, socket)
        [] ->
          {:noreply, socket}
      end
    end
  end

  @impl true
  def handle_event("keyboard_navigation", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :show_suggestions, false)}
  end

  @impl true
  def handle_event("focus", _params, socket) do
    suggestions = 
      if String.length(String.trim(socket.assigns.query)) >= 2 do
        socket.assigns.suggestions
      else
        []
      end
    
    {:noreply, assign(socket, :show_suggestions, length(suggestions) > 0)}
  end

  @impl true
  def handle_event("blur", _params, socket) do
    # Hide suggestions immediately on blur - let click events handle their own logic
    {:noreply, assign(socket, :show_suggestions, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative">
      <input
        type="text"
        value={@query}
        placeholder={@placeholder}
        class={["w-full", @class]}
        phx-change="input_change"
        phx-keydown="keyboard_navigation"
        phx-focus="focus"
        phx-blur="blur"
        phx-target={@myself}
        autocomplete="off"
      />
      
      <%= if @show_suggestions and length(@suggestions) > 0 do %>
        <div class="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
          <%= for {suggestion, index} <- Enum.with_index(@suggestions) do %>
            <div
              class={[
                "px-4 py-3 cursor-pointer border-b border-gray-100 last:border-b-0 hover:bg-gray-50",
                if(index == @selected_index, do: "bg-orange-50 border-l-4 border-l-orange-500", else: "")
              ]}
              phx-click="select_suggestion"
              phx-value-index={index}
              phx-target={@myself}
            >
              <div class="flex items-center">
                <.icon name="hero-map-pin" class="w-4 h-4 text-gray-400 mr-3 flex-shrink-0" />
                <div class="flex-1">
                  <div class="text-sm font-medium text-gray-900">
                    {suggestion.display}
                  </div>
                  <%= if Map.has_key?(suggestion, :postal_code) and suggestion.postal_code do %>
                    <div class="text-xs text-gray-500">
                      📮 {suggestion.postal_code}
                      <%= if Map.has_key?(suggestion, :city) and suggestion.city do %>
                        • {suggestion.city}
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
          
          <!-- Powered by notice for production -->
          <div class="px-4 py-2 text-xs text-gray-400 bg-gray-50 border-t">
            🇳🇱 Dutch address lookup powered by postal codes
          </div>
        </div>
      <% end %>
      
      <%= if @show_suggestions and length(@suggestions) == 0 and String.length(String.trim(@query)) >= 2 do %>
        <div class="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg">
          <div class="px-4 py-3 text-sm text-gray-500">
            <.icon name="hero-magnifying-glass" class="w-4 h-4 mr-2 inline" />
            No addresses found for "{@query}"
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
