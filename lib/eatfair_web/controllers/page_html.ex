defmodule EatfairWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use EatfairWeb, :html

  embed_templates "page_html/*"

    @doc """
  Renders a cuisine category card.
  """
  attr :name, :string, required: true
  attr :image_url, :string, required: true

  def cuisine_card(assigns) do
    ~H"""
    <a href="#" class="group block">
      <div class="relative overflow-hidden rounded-lg shadow-lg transition-transform duration-300 group-hover:scale-105">
        <img src={@image_url} alt={"Image of " <> @name} class="h-40 w-full object-cover" onerror={"this.onerror=null;this.src='https://placehold.co/300x200/cccccc/FFFFFF?text=Image+Not+Found';"} />
        <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
        <div class="absolute bottom-0 left-0 p-4">
          <h3 class="text-lg font-semibold text-white"><%= @name %></h3>
        </div>
      </div>
    </a>
    """
  end

  @doc """
  Renders a featured restaurant card.
  """
  attr :name, :string, required: true
  attr :cuisine, :string, required: true
  attr :delivery_time, :string, required: true
  attr :rating, :string, required: true
  attr :image_url, :string, required: true

  def restaurant_card(assigns) do
    ~H"""
    <div class="group relative block overflow-hidden rounded-lg bg-white shadow-md transition-shadow duration-300 hover:shadow-xl">
      <img
        src={@image_url}
        alt={"Image of " <> @name}
        class="h-48 w-full object-cover transition-transform duration-300 group-hover:scale-105"
        onerror={"this.onerror=null;this.src='https://placehold.co/400x250/cccccc/FFFFFF?text=Restaurant';"}
      />
      <div class="p-4">
        <div class="flex items-baseline justify-between">
          <h3 class="text-lg font-bold text-gray-900"><%= @name %></h3>
          <div class="ml-2 flex items-center rounded-full bg-orange-100 px-2 py-1 text-xs font-semibold text-orange-600">
            <!-- Star Icon -->
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="h-4 w-4 mr-1">
              <path fill-rule="evenodd" d="M10.868 2.884c.321-.662 1.215-.662 1.536 0l1.681 3.46c.154.318.46.533.806.578l3.81.553c.73.106 1.023.998.494 1.503l-2.758 2.688a.996.996 0 00-.287.885l.65 3.794c.125.726-.635 1.28-1.29.942l-3.402-1.789a.997.997 0 00-.92 0l-3.402 1.789c-.655.338-1.415-.216-1.29-.942l.65-3.794a.996.996 0 00-.287-.885L2.32 9.08c-.53-.505-.237-1.397.494-1.503l3.81-.553a.997.997 0 00.806-.578L9.132 2.884z" clip-rule="evenodd" />
            </svg>
            <%= @rating %>
          </div>
        </div>
        <p class="mt-2 text-sm text-gray-600"><%= @cuisine %></p>
        <p class="mt-2 text-sm font-medium text-gray-700"><%= @delivery_time %></p>
      </div>
    </div>
    """
  end
end
