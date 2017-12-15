require Logger

defmodule S3SyncEx do
  @moduledoc """
  Documentation for S3SyncEx.
  """

  def sync(src, bucket, key, secret, folder \\ nil, aws_opts \\ []) do
    Logger.info("Syncing from #{src} to bucket #{bucket}, folder #{folder} with aws_opts #{inspect aws_opts}")
    config = ExAws.Config.new(:s3, [access_key_id: key,secret_access_key: secret])
    bucket
    |> ExAws.S3.list_objects
    |> ExAws.request!(config)
    |> Map.get(:body)
    |> Map.get(:contents)
    |> Enum.map(&Map.get(&1, :key))
    |> Enum.filter(&correct_folder(&1, folder))
    |> Enum.map(fn rf ->
      if !File.exists?(to_local_full_path(rf, folder, src)) do
        Logger.info "Deleting #{rf}"
        ExAws.S3.delete_object(bucket, rf) |> ExAws.request!(config)
      end      
    end)
    
    S3SyncEx.FlatFiles.list_all(src)
    |> Enum.map(&Path.relative_to(&1, src))
    |> Enum.map(fn f ->
      Task.async(fn ->
        Logger.info "Putting #{to_remote_object_name(f, folder)}"
        bucket
        |> ExAws.S3.put_object(to_remote_object_name(f, folder), File.read!(to_local_folder(f, src)), [content_type: MIME.from_path(f)] ++ aws_opts)
        |> ExAws.request!(config)
      end)
    end)
    |> Enum.map(&Task.await(&1, 30_000))
    Logger.info "Completed sync"
  end

  def to_remote_object_name(obj, :na), do: obj
  def to_remote_object_name(obj, folder), do: "#{folder}/#{obj}"

  def to_local_folder(obj, src), do: "#{src}/#{obj}"
  def to_local_full_path(remote_object_name, nil, src), do: src <> "/" <> remote_object_name
  def to_local_full_path(remote_object_name, remote_folder, src), do: src <> String.slice(remote_object_name, String.length(remote_folder)..-1)

  def correct_folder(_, nil), do: true
  def correct_folder(obj, folder), do: String.starts_with?(obj, folder)

end
