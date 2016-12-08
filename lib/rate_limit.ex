defmodule RateLimit do
  @moduledoc """
  A rate limiting module.

  ## Configuration

  Default values for `max_requests` and `reset_interval` can be set by
  setting values in your mix config.

  Additionally, an engine can be specified via the `:engine` key. By default
  RateLimit will use an ETS based engine.

  ```
  config :rate_limit,
    default_max_requests: 1_000
    default_reset_interval: 30 * 60 * 1_000
  ```

  """

  import RateLimit.Utils, only: [{:timestamp, 0}]


  @typedoc """
  An identifier for an individual rate limiter.

  """
  @type id :: String.t

  @type counter :: {id, used_count :: non_neg_integer, reset_at :: pos_integer}

  @type access_opt ::
    {:count, pos_integer} |
    {:max_requests, pos_integer} |
    {:reset_interval, pos_integer}

  @default_max_reqs Application.get_env(:rate_limit, :default_max_requests, 100)
  @default_reset_interval Application.get_env(:rate_limit, :default_reset_interval, 3_600_000)
  @engine Application.get_env(:rate_limit, :engine, RateLimit.Engine.ETS)

  @doc """
  Requests access to the resource.

  Returns `:ok` if access is allowed, or `{:error, String.t}` if
  it is not.

  Takes the following options:

  - `count` - the number of requests the access will consume. Default: `1`.
  - `max_requests` - the maximum number of requests allowed in the `reset_interval`. Default: 100
  - `reset_interval` - the time (in milliseconds) that the count will be reset. Default: `3_600_000` (1 hour)

  """
  @spec access(id, [access_opt]) :: :ok | {:error, String.t}
  def access(id, opts \\ []) do
    {count, max_reqs, reset_interval} =
      read_opts(opts)

    @engine.incr(id, count, max_reqs, timestamp + reset_interval)
  end

  @doc """
  Resets the counter to 0 for the specified ID.

  """
  @spec reset(id) :: :ok | {:error, String.t}
  def reset(id) do
    @engine.reset(id)
  end

  @spec read_opts([access_opt]) :: {pos_integer, non_neg_integer, pos_integer}
  defp read_opts(opts) do
    count =
      Keyword.get(opts, :count, 1)

    max_reqs =
      Keyword.get(opts, :max_requests, @default_max_reqs)

    reset_interval =
      Keyword.get(opts, :reset_interval, @default_reset_interval)

    {count, max_reqs, reset_interval}
  end

end
