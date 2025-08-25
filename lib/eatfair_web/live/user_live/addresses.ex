defmodule EatfairWeb.UserLive.Addresses do
  use EatfairWeb, :live_view

  alias Eatfair.Accounts
  alias Eatfair.Accounts.Address

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    addresses = Accounts.list_user_addresses(user.id)
    
    {:ok, 
     socket
     |> assign(:page_title, "Your Addresses")
     |> assign(:addresses, addresses)
     |> assign(:show_form, false)
     |> assign(:form, to_form(Accounts.change_address(%Address{})))}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  @impl true
  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, :show_form, false)}
  end

  @impl true
  def handle_event("save_address", %{"address" => address_params}, socket) do
    user = socket.assigns.current_scope.user
    address_params = Map.put(address_params, "user_id", user.id)

    case Accounts.create_address(address_params) do
      {:ok, _address} ->
        addresses = Accounts.list_user_addresses(user.id)
        {:noreply,
         socket
         |> assign(:addresses, addresses)
         |> assign(:show_form, false)
         |> assign(:form, to_form(Accounts.change_address(%Address{})))
         |> put_flash(:info, "Address saved successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("set_default", %{"id" => id}, socket) do
    user = socket.assigns.current_scope.user
    
    case Accounts.set_default_address(user.id, String.to_integer(id)) do
      {:ok, _address} ->
        addresses = Accounts.list_user_addresses(user.id)
        {:noreply,
         socket
         |> assign(:addresses, addresses)
         |> put_flash(:info, "Default address updated")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update default address")}
    end
  end

  @impl true
  def handle_event("delete_address", %{"id" => id}, socket) do
    address = Accounts.get_address!(String.to_integer(id))
    
    case Accounts.delete_address(address) do
      {:ok, _address} ->
        user = socket.assigns.current_scope.user
        addresses = Accounts.list_user_addresses(user.id)
        {:noreply,
         socket
         |> assign(:addresses, addresses)
         |> put_flash(:info, "Address deleted")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not delete address")}
    end
  end
end
