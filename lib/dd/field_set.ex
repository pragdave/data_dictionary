defmodule DD.FieldSet do


  if Code.ensure_loaded?(Ecto.Changeset) do
    def from(module, %Ecto.Changeset{errors: errors, data: data}) do
      values = module.__defaults |> Map.merge(data)
      module.__blank_fieldset
      |> Map.put(:values, values)
      |> Map.put(:errors, errors)
    end
  end
  
  def from(module, new_values) do
    base =
      module.__blank_fieldset
      |> Map.put(:values, module.__defaults)

    update(module, base, new_values)
  end
  
  def update(module, current, new_values) do
    values =
      new_values
      |> convert_incoming_types(module.__fields)

    values = Map.merge(current.values, values)
    
    current
    |> Map.put(:values, values)
    |> Map.put(:fields, module.__fields)
    |> DD.Validate.update_errors(module)
  end

  
  def hidden_fields(module) do
    module.fields
    |> Enum.filter(fn {_name, defn} -> defn.options[:hidden] end)
    |> Enum.map(&elem(&1, 0))
  end

  
  ############################################################

  defp convert_incoming_types(values, fields) do
    values
    |> Enum.map(fn {name, value} ->
      name = name |> to_atom()
      options = fields[name].options
      value = fields[name].type.from_display_value(value, options)
      { name, value }
    end)
    |> Enum.into(%{})
  end

  
  defp to_atom(k) when is_atom(k), do: k
  defp to_atom(k),                 do: String.to_atom(k)


end