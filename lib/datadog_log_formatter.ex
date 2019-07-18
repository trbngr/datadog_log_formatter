defmodule DatadogLogFormatter do
  alias DatadogLogFormatter.{Timestamp, Metadata}

  def format(level, message, timestamp, metadata) do
    {:ok, hostname} = :inet.gethostname()

    options =
      Application.get_env(:logger, :datadog_log_formatter,
        service: :elixir,
        host: List.to_string(hostname),
        environment: System.get_env("DD_APP_ENV") || "Dev",
        filter_keys: ["password", "secret"],
        mask_keys: [
          ssn: {Mask, :ssn}
        ]
      )

    values = %{
      message:
        case message do
          message when is_list(message) -> IO.iodata_to_binary(message)
          message -> message
        end,
      level: level,
      source: :elixir,
      timestamp: Timestamp.datetime(timestamp),
      host: options[:host],
      service: options[:service],
      environment: options[:environment]
    }

    metadata = Metadata.normalize(metadata, options)

    message =
      values
      |> Map.merge(metadata)
      |> Jason.encode_to_iodata!()

    message ++ [?\n]
  end
end
