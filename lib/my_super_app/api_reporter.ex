defmodule MySuperApp.ApiReporter do
  require Logger

  @moduledoc """
  Shows executing duration of API requests.
  """

  def handle_event([:phoenix, :endpoint, :stop], measurements, %{conn: conn}, _config) do
    duration_in_ms = measurements.duration / 1_000_000

    if api_request?(conn) do
      path = conn.request_path
      Logger.info("API request to #{path} took #{duration_in_ms} ms")
    end
  end

  defp api_request?(conn) do
    String.starts_with?(conn.request_path, "/api/")
  end
end
