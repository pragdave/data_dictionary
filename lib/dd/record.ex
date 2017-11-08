defmodule DD.Record do

  def from(module, new_values) do
    new_values = convert_incoming_types(new_values, module.__fields)
    
    values = Map.merge(module.__defaults, new_values)
    
    module.__blank_record
    |> Map.put(:values, values)
    |> Map.put(:fields, module.__fields)
    |> DD.Validate.update_errors(module)
  end

  def hidden_fields(module) do
    module.__fields()
    |> Enum.filter(fn {name, defn} -> defn.options[:hidden] end)
    |> Enum.map(&elem(&1, 0))
  end

  ############################################################

  defp convert_incoming_types(values, fields) do
    values
    |> Enum.map(fn {name, value} ->
      name = name |> to_atom()
      value = value |> fields[name].type.from_display_value()
      { name, value }
    end)
    |> to_map
  end

  
  defp to_map(new_values) when is_map(new_values) do
    new_values
  end
  
  defp to_map(new_values) do
    new_values |> Enum.into(%{})
  end

  defp to_atom(k) when is_atom(k), do: k
  defp to_atom(k),                 do: String.to_atom(k)


end
