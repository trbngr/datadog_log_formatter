defmodule DatadogLogFormatterTest do
  use ExUnit.Case
  doctest DatadogLogFormatter

  test "greets the world" do
    assert DatadogLogFormatter.hello() == :world
  end
end
