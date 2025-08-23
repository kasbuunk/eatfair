defmodule EatfairWeb.PageController do
  use EatfairWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
