defmodule RateLimit.Engine.ETS do
  @moduledoc false

  alias RateLimit.Engine

  import RateLimit.Utils, only: [{:timestamp, 0}]

  @behaviour Engine

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    table =
      :ets.new(:rate_limit_ets, [])

    {:ok, table}
  end

  def incr(id, count, max, expire) do
    GenServer.call(__MODULE__, {:incr, id, count, max, expire})
  end

  def reset(id) do
    GenServer.call(__MODULE__, {:reset, id})
  end

  def handle_call({:incr, id, count, max, expire_at}, _caller, table) do
    counter =
      case :ets.lookup(table, id) do
        [] ->
          Process.send_after(self, {:expire, id}, expire_at - timestamp)
          {id, 0, expire_at}

        [counter] ->
          counter
      end


    reply =
      with {:ok, updated_counter} <- use_requests(counter, count, max) do
        :ets.insert(table, updated_counter)
        {:ok, updated_counter}
      end

    {:reply, reply, table}
  end

  def handle_call({:reset, id}, _caller, table) do
    :ets.delete(table, id)
    {:reply, :ok, table}
  end

  defp use_requests({id, used_count, expire_at}, count, max) do
    cond do
    used_count + count > max and count == 1 ->
      {:error, "Rate limit exceeded"}
    used_count + count > max and count > 1 ->
      {:error, "Using #{count} requests would exceed rate limit"}
    true ->
      {:ok, {id, used_count + count, expire_at}}
    end
  end

  def handle_info({:expire, id}, table) do
    :ets.delete(table, id)
    {:noreply, table}
  end

end
