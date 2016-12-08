defmodule RateLimit.Engine do
  @moduledoc """
  Behaviour module defining the callbacks for a storage engine.

  By default `RateLimit` ships with (and uses) `RateLimit.Engine.ETS` but
  this can be configured by specifying the `:engine` value in the `config.exs`.

  """

  alias RateLimit

  @doc """
  GenServer based start_link callback used by the supervisor

  """
  @callback start_link :: GenServer.on_start

  @doc """
  Callback to increment the specified counter by the requested amount.

  If incrementing `id` by `count` would exceed `max` an error should be
  returned and the counter should not be incremented.

  The counter should expire in `expire` millis if it is being created.

  """
  @callback incr(
    id :: RateLimit.id,
    count :: pos_integer,
    max :: pos_integer,
    expire :: pos_integer
  ) :: {:ok, RateLimit.counter} | {:error, String.t}

  @doc """
  Callback to reset the specified counter to 0

  """
  @callback reset(id :: RateLimit.id) :: :ok | {:error, String.t}
end
