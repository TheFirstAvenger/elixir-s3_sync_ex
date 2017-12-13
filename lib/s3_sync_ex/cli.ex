defmodule S3SyncEx.CLI do

  def main(args \\ []) do
    args
    |> parse_args
    |> sync
  end

  defp parse_args(args) do
    {opts, _, _} = args
    |> OptionParser.parse(switches: [src: :string, bucket: :string, key: :string, secret: :string, folder: :string])
    {opts[:src], opts[:bucket], opts[:key], opts[:secret], opts[:folder]}
    |> IO.inspect
  end

  defp sync({src, bucket, key, secret, folder}) when is_nil(key) or is_nil(secret), do: S3SyncEx.sync(src, bucket, env_key, env_secret, folder)
  defp sync({src, bucket, key, secret, folder}), do: S3SyncEx.sync(src, bucket, key, secret, folder)

  defp env_key, do: System.get_env("AWS_ACCESS_KEY_ID")
  defp env_secret, do: System.get_env("AWS_SECRET_ACCESS_KEY")

end