defmodule DD.Type.String do

  ########################################
  @behaviour DD.Type.Behaviour
  ########################################

  def from_options(_name, spec) do
    spec |> valid_options()
  end
  

  def validate(value, _) when not is_binary(value) do
    { "%{value} should be a string", inspect(value) }
  end

  def validate(value, specs) do
    validate_length(String.length(value), specs[:min], specs[:max])
    || validate_matches(value, specs[:matches])
  end

  def to_display_value(value, _) do
    value
  end

  def from_display_value(value, _options)  when is_binary(value) do
    value
  end

  def from_display_value(value, _options) do
    inspect(value)
  end




  
  ##########
  # length #
  ##########
  
  defp validate_length(_length, nil, nil), do: nil

  defp validate_length(length,  min, max) do
    cond do
      min && length < min ->
        {
          "must be at least %{min} characters long  (its length is %{length})",
          min: min, length: length
        }
        
      max && length > max ->
        {
          "cannot be longer than %{max} characters (its length is %{length})",
          max: max, length: length
        }
      true ->
        nil
    end
  end

  ###########
  # matches #
  ###########
  
  defp validate_matches(_value, nil), do: nil

  defp validate_matches(value, re) do
    if value =~ re do
      nil
    else
      { "must match the pattern %{re}", re: inspect(re) }
    end
  end


  ###################
  # Option handling #
  ###################

  defp valid_options(options) do
    options
    |> Enum.map(&valid_option/1)
  end
    
  defp valid_option({:min, n}) when is_integer(n) and n >= 0 do
    { :min, n }
  end
  
  defp valid_option({:max, n}) when is_integer(n) and n >= 0 do
    { :max, n }
  end

  defp valid_option({:matches, pattern}) when is_binary(pattern) do
    { :matches, Regex.compile!(pattern) }
  end

  defp valid_option({:matches, pattern}) do
    { :matches, pattern }
  end

  defp valid_option({name, value}) do
    DD.Type.valid_option({name, value})
  end
end
