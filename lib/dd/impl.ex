defmodule DD.Impl do
  
  defmacro deffieldset(do: field_list) do

    field_list = normalize_field_list(field_list)
    defaults   = extract_defaults_from(field_list)

    quote do
      try do

        @__fields unquote(field_list)
        def __fields(), do: @__fields

        def __defaults(), do: unquote(Macro.escape(defaults))
        
      after
        :ok
      end
    end
       

  end


  if Code.ensure_loaded?(Phoenix.HTML.FormData) do
    defimpl(Phoenix.HTML.FormData, for: Any) do
      defdelegate to_form(fieldset, opts),              to: DD.FormData
      defdelegate to_form(fieldset, a, b, opts),        to: DD.FormData
      defdelegate input_validations(data, form, field), to: DD.FormData
      defdelegate input_value(data, form, field),       to: DD.FormData
      defdelegate input_type(data, form, field),        to: DD.FormData
    end
  end

  defimpl(String.Chars, for: Any) do
    defdelegate to_string(fieldset), to: DD.FieldSet.ToString
  end
  
  defmacro __using__(_) do
    quote do
      require Protocol
      
      import DD.Impl, only: [ deffieldset: 1 ]
      
      defstruct values: nil, errors: %{}, fields: %{}

      if Code.ensure_loaded?(Phoenix.HTML) do
        Protocol.derive(Phoenix.HTML.FormData, __MODULE__)
      end
      Protocol.derive(String.Chars,          __MODULE__)

      def __blank_fieldset, do: %__MODULE__{}
      
      def new(values \\ []) do
        DD.FieldSet.from(__MODULE__, values)
      end

      def update(current = %__MODULE__{}, new_values) do
        DD.FieldSet.update(__MODULE__, current, new_values)
      end

      def valid?(%{ errors: %{}}), do: true
      def valid?(_),               do: false
    end
  end


  defp normalize_field_list({:__block__, _context, fields}) do
      fields
      |> Enum.map(&convert_one_field/1)
  end

  
  defp normalize_field_list(field = {_type, _context, _args}) do
    [ convert_one_field(field) ]
  end

  defp convert_one_field({type, context, [ name ]}) do
    convert_one_field({type, context, [ name, [] ]})
  end

  defp convert_one_field({type, context, [ name, _spec ]})
  when is_binary(name) do
    convert_one_field({type, context, [ String.to_atom(name), [] ]})    
  end

  defp convert_one_field({type, _context, [ name, spec ]})
  when is_atom(name) and is_list(spec) do
    type_module = DD.Type.find_definition(type)
    {options, _} = spec |> Code.eval_quoted(spec)
    spec = type_module.from_options(name, options)
           |> handle_global_options()

    quote do
      {
        unquote(name),
        %{
          type:    unquote(type_module),
          options: unquote(spec |> Macro.escape)
        }
      }
    end

  end


  # World's ugliest function. We take the list of fields,
  # which is quoted code. We evaluation it to get a list of fields
  # as terms. These look like
  #
  #    { name, {type: type, options: options }}
  #
  # We extract the name, type, and default value, eliminate
  # fields with no default, run that default through the
  # type-specific external-to-internal convertor, then
  # return a map of { name, internal_default} values.
  
  defp extract_defaults_from(field_list) do
    field_list
    |> Code.eval_quoted
    |> elem(0)
    |> Enum.map(fn { name, rest } ->
      { name, rest.type, rest.options, rest.options[:default] }
    end)
    |> Enum.map(&maybe_convert_from_display/1)
    |> Enum.into(%{})
  end

  defp maybe_convert_from_display({name, _type, _, nil}) do
    { name, nil }
  end

  defp maybe_convert_from_display({name, type, options, value}) do
    { name, type.from_display_value(value, options) }
  end
  
  # This handles setting the optional flag. If `:opt` has been
  # given, remap it to `:optional`. If `:optional` is present, then we're
  # good. Otherwise set `:optional` to false.
  
  defp handle_global_options(spec) do
    convert_opt_to_optional(spec)
  end

  defp convert_opt_to_optional(spec) do
    cond do
      Keyword.has_key?(spec, :optional) ->
        spec
      Keyword.has_key?(spec, :opt) ->
        opt = spec[:opt]
        spec
        |> Keyword.delete(:opt)
        |> Keyword.put(:optional, opt)
      true ->
        Keyword.put(spec, :optional, false)
    end
  end
end
