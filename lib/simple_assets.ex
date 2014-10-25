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
