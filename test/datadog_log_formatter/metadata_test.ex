defmodule DatadogLogFormatter.MetadataTest do
  use ExUnit.Case
  alias DatadogLogFormatter.Metadata
  alias DatadogLogFormatter.Mask

  defmodule Ssn, do: defstruct([:ssn])
  defmodule Password, do: defstruct([:password])

  test "filtering" do
    result =
      Metadata.normalize(
        [
          password: "secretshithere",
          nested: %{
            password: "secretshithere"
          },
          struct: %Password{password: "secretshithere"}
        ],
        filter_keys: ["password"]
      )

    assert result == %{
             "nested" => %{"password" => "[FILTERED]"},
             "password" => "[FILTERED]",
             "struct" => %{
               "password" => "[FILTERED]",
               "type" => "DatadogLogFormatter.MetadataTest.Password"
             }
           }
  end

  test "masking" do
    result =
      Metadata.normalize(
        [
          ssn: "111-11-1111",
          nested: %{
            ssn: "111111111"
          },
          struct: %Ssn{ssn: "111111111"}
        ],
        mask_keys: %{
          "ssn" => {Mask, :ssn}
        }
      )

    assert result == %{
             "nested" => %{"ssn" => "***-**-1111"},
             "ssn" => "***-**-1111",
             "struct" => %{
               "ssn" => "***-**-1111",
               "type" => "DatadogLogFormatter.MetadataTest.Ssn"
             }
           }
  end
end
