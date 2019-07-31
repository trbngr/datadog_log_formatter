defmodule DatadogLogFormatter do
  alias DatadogLogFormatter.{Timestamp, Metadata, Mask}

  def format(level, message, timestamp, metadata) do
    options = read_options()

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

  @default_options [
    service: :elixir,
    environment: "Dev",
    filter_keys: ["password", "secret"],
    mask_keys: [
      ssn: {Mask, :ssn}
    ]
  ]

  def read_options() do
    opts =
      Application.get_env(:logger, :datadog_log_formatter, @default_options)
      |> Keyword.merge(@default_options, fn _, given, _default -> given end)

    put_host(opts, opts[:host])
  end

  defp put_host(opts, nil) do
    {:ok, hostname} = :inet.gethostname()
    Keyword.put(opts, :host, to_string(hostname))
  end

  defp put_host(opts, _hostname), do: opts
end
