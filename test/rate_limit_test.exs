defmodule RateLimitTest do
  use ExUnit.Case
  doctest RateLimit

  test "access/2 rate limits" do
    assert {:ok, _} = RateLimit.access("test-access")
    assert {:error, "Rate limit exceeded"} = RateLimit.access("test-access")
  end

  test "access/2 rate limits requests that would exceed" do
    assert {:ok, _} = RateLimit.access("test-multi-req", max_requests: 5)
    assert {:error, "Using 5 requests would exceed rate limit"} = RateLimit.access("test-multi-req", count: 5)
  end

  test "access/2 resets eventually" do
    assert {:ok, _} = RateLimit.access("test-reset")
    Process.sleep(50)
    assert {:ok, _} = RateLimit.access("test-reset")
  end

  test "access/2 rate limits on first request" do
    assert {:error, "Using 100 requests would exceed rate limit"}
      = RateLimit.access("first-request", count: 100, max_requests: 50)
  end

  test "reset/1 resets the limit" do
    assert {:ok, _} = RateLimit.access("reset-test")
    assert :ok == RateLimit.reset("reset-test")
    assert {:ok, _} = RateLimit.access("reset-test")
  end

end
