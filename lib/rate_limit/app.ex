defmodule RateLimit.App do
  @moduledoc """
  Application module for the RateLimit App.

  """
  use Application

  alias RateLimit.Engine.ETS

  @engine Application.get_env(:rate_limit, :engine, ETS)

  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(@engine, []),
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: RateLimit.Supervisor)
  end
end
