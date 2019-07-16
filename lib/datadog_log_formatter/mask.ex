defmodule DatadogLogFormatter.Mask do
  def ssn(<<_::size(3)-bytes, "-", _::size(2)-bytes, "-", last_four::size(4)-bytes>>),
    do: ssn_format(last_four)

  def ssn(<<_::size(5)-bytes, last_four::size(4)-bytes>>),
    do: ssn_format(last_four)

  def ssn(value), do: value

  defp ssn_format(last_four), do: "***-**-" <> last_four
end
