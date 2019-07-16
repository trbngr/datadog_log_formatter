defmodule DatadogLogFormatter do
  alias DatadogLogFormatter.{Timestamp, Metadata}

  def format(level, message, timestamp, metadata) do
    options =
      Application.get_env(:logger, :datadog_log_formatter,
        service: :elixir,
        filter_keys: ["password", "secret"],
        mask_keys: [
          ssn: {Mask, :ssn}
        ]
      )

    {:ok, hostname} = :inet.gethostname()

    values = %{
      message:
        case message do
          message when is_list(message) -> IO.iodata_to_binary(message)
          message -> message
        end,
      level: level,
      source: :elixir,
      timestamp: Timestamp.datetime(timestamp),
      host: List.to_string(hostname),
      service: options[:service],
      environment: System.get_env("DD_APP_ENV") || "Dev"
    }

    metadata = Metadata.normalize(metadata, options)

    message =
      values
      |> Map.merge(metadata)
      |> Jason.encode_to_iodata!()

    message ++ [?\n]
  end
end
