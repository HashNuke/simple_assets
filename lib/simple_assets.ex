defmodule SimpleAssets do
  use Rotor.Config
  import CoffeeRotor
  import SassRotor
  import SimpleAssets.Rotors

  # NOT TESTED won't work
  # TODO digested output has to be stored in the application env, as a map, so that it's accessible in the templates.
  # so the hash would contain %{"file name" => "digest"}


  def start(options) do
    options = determine_options(options)
    File.mkdir_p!(options[:output_path])


    rotor_options = %{manual: true}
    Rotor.watch :coffeescripts, options.javascript_paths, fn(_changed_files, all_files)->
      read_files(all_files)
      |> coffee
      |> concat
      |> digested_output_to(options[:output_path], "js")
    end, rotor_options


    Rotor.watch :stylesheets, options.stylesheet_paths, fn(_changed_files, all_files)->
      read_files(all_files)
      |> sass
      |> concat
      |> digested_output_to(options[:output_path], "css")
    end, rotor_options



    Rotor.watch :other_paths, other_asset_paths(options.base_path), fn(changed, _all)->
      read_files(changed)
      |> copy_files_with_digest_in_name(changed)
    end, rotor_options
  end


  defp other_asset_paths(base_path) do
    File.ls!(".")
    |> Enum.filter(&File.dir?/1)
    |> Enum.map( fn(dir)-> "#{base_path}/#{dir}/*" end )
  end


  defp determine_options(options) do
    default_options = %{
      base_path: "priv/assets",
      use_digest: true,
      output_path: "priv/static/assets"
    }

    merge_options(default_options, options)
  end


  defp merge_options(options1, options2) do
    options = Map.merge(options1, options2)

    Map.put(options, :javascript_paths, ["#{options.base_path}/javascripts"])
    |> Map.put(:stylesheet_paths, ["#{options.base_path}/stylesheets"])
  end

end


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
