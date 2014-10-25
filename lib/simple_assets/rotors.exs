defmodule SimpleAssets.Rotors do
  import Rotor.BasicRotors

  def digested_output_to(contents, output_dir, extension) do
    digest = calculate_digest(contents)
    "#{output_dir}/app-#{digest}.#{extension}"
  end


  def copy_files_with_digest_in_name([], files_with_new_name) do
    copy_files(files_with_new_name)
  end


  def copy_files_with_digest_in_name([file | files], files_with_new_name) do
    new_file = %{file | name: name_with_digest(file)}
    copy_files_with_digest_in_name files, [new_file | files_with_new_name]
  end


  defp name_with_digest(file) do
    file_name_parts = String.split(file.name, ".")
    number_of_parts = length(file_name_parts)
    index_to_replace = case number_of_parts do
      1 -> 0
      _ -> number_of_parts - 2
    end
    part   = Enum.at file_name_parts, index_to_replace
    digest = calculate_digest(file.contents)
    new_part_name = "#{part}-#{digest}"

    List.replace_at file_name_parts, index_to_replace, new_part_name
  end


  defp calculate_digest(contents) do
    :crypto.sha_mac("rotor", contents) |> Base.encode16 |> String.downcase
  end
end
