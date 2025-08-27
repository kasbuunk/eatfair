defmodule EatfairWeb.Plugs.Observability do
  @moduledoc """
  Plug for injecting observability metadata into request lifecycle.

  This plug ensures that all requests have proper version, user, and context
  metadata for correlation with user feedback and troubleshooting.
  """

  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    # Inject version metadata into logger for this request
    Logger.metadata(version: Eatfair.Version.get())

    # Add request metadata for observability
    metadata = build_request_metadata(conn)
    Logger.metadata(metadata)

    # Emit telemetry event for request with version
    :telemetry.execute(
      [:eatfair, :web, :request, :start],
      %{count: 1},
      Map.merge(metadata, %{
        request_path: conn.request_path,
        method: conn.method,
        remote_ip: get_remote_ip(conn)
      })
    )

    conn
  end

  defp build_request_metadata(conn) do
    base_metadata = %{
      version: Eatfair.Version.get(),
      request_id: get_request_id(conn),
      page_url: build_page_url(conn)
    }

    # Add user metadata if available
    case get_current_user(conn) do
      %{id: user_id} -> Map.put(base_metadata, :user_id, user_id)
      _ -> base_metadata
    end
  end

  defp get_request_id(conn) do
    case get_resp_header(conn, "x-request-id") do
      [request_id] ->
        request_id

      [] ->
        # Phoenix should have set this, but fallback to connection ID
        conn.assigns[:request_id] || "unknown-#{System.unique_integer()}"
    end
  end

  defp build_page_url(conn) do
    case conn.scheme do
      :https -> "https://"
      _ -> "http://"
    end
    |> Kernel.<>(conn.host)
    |> Kernel.<>(if conn.port != 80 and conn.port != 443, do: ":#{conn.port}", else: "")
    |> Kernel.<>(conn.request_path)
    |> Kernel.<>(if conn.query_string != "", do: "?#{conn.query_string}", else: "")
  end

  defp get_current_user(conn) do
    # Check for current user in different possible assign keys
    conn.assigns[:current_user] ||
      case conn.assigns[:current_scope] do
        %{user: user} -> user
        _ -> nil
      end
  end

  defp get_remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded_ip | _] ->
        forwarded_ip
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end
end
