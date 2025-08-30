defmodule EatfairWeb.PageController do
  use EatfairWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def terms(conn, _params) do
    render(conn, :terms, page_title: "Terms of Service")
  end

  def privacy(conn, _params) do
    render(conn, :privacy, page_title: "Privacy Policy")
  end
end
