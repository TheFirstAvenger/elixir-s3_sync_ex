defmodule S3SyncEx.CLI do

  def main(args \\ []) do
    args
    |> parse_args
    |> IO.inspect
    #|> sync
  end

  defp parse_args(args) do
    {opts, _, _} = args
    |> OptionParser.parse(switches: [src: :string, bucket: :string, key: :string, secret: :string, folder: :string, public: :boolean])
    aws_opts = cond do
      opts[:public] -> [acl: :public_read]
      true -> []
    end
    {opts[:src], opts[:bucket], opts[:key], opts[:secret], opts[:folder], aws_opts}
  end

  defp sync({src, bucket, key, secret, folder, public}) when is_nil(key) or is_nil(secret), do: S3SyncEx.sync(src, bucket, env_key, env_secret, folder, public)
  defp sync({src, bucket, key, secret, folder, public}), do: S3SyncEx.sync(src, bucket, key, secret, folder, public)

  defp env_key, do: System.get_env("AWS_ACCESS_KEY_ID")
  defp env_secret, do: System.get_env("AWS_SECRET_ACCESS_KEY")

end