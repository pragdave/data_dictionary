defmodule DD.Validate do


  def update_errors(record, module) do
    %{ record | errors: errors_for(record, module) }
  end

  defp errors_for(record, module) do
    errors_for_each_field(record, module)
    |> remove_entries_for_fields_with_no_errors()
  end

  defp errors_for_each_field(record, module) do
    module.__fields
    |> Enum.reduce({ record, [] }, &errors_for_one_field/2)
    |> elem(1)
  end

  defp remove_entries_for_fields_with_no_errors(errors) do
    errors
    |> Enum.filter(fn { _, {error, _opts} } -> error end)
  end


  defp errors_for_one_field({name, defn}, { record, result }) do
    value = record.values[name]
    error =
      cross_type_validations(value, defn.options) ||
      type_specific_validations(defn.type, value, defn.options)
    
    { record, [ { name, { error, [] } } | result ] }
  end


  ####################################
  #  Validations common to all types #
  ####################################
  
  defp cross_type_validations(value, specs) do
    validate_present(value, specs[:default])
  end

  defp validate_present(value, _default = nil) when value == nil do
    "requires a value"
  end

  defp validate_present(value, _default = nil) when value == "" do
    "requires a value"
  end

  defp validate_present(a, b) do
    nil
  end

  #########################################
  # Dispatch to type-specific validations #
  #########################################

  defp type_specific_validations(type, value, specs) do
    type.validate(value, specs)
  end
end
