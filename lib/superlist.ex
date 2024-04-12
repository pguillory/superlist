defmodule SuperList do
  @max_arity Application.compile_env(:superlist, :max_arity, 25)

  for arity <- 1..@max_arity do
    heads = Enum.map(1..arity, &Macro.var(:"head#{&1}", __MODULE__))
    tails = Enum.map(1..arity, &Macro.var(:"tail#{&1}", __MODULE__))
    lists = Enum.map(1..arity, &Macro.var(:"list#{&1}", __MODULE__))

    heads_and_tails =
      Enum.map(1..arity, fn i ->
        quote do
          [
            unquote(Macro.var(:"head#{i}", __MODULE__))
            | unquote(Macro.var(:"tail#{i}", __MODULE__))
          ]
        end
      end)

    reversed_lists =
      Enum.map(1..arity, fn i ->
        quote do
          Enum.reverse(unquote(Macro.var(:"list#{i}", __MODULE__)))
        end
      end)

    empty_lists =
      Enum.map(1..arity, fn _ ->
        quote do
          []
        end
      end)

    underscores =
      Enum.map(1..arity, fn _ ->
        quote do
          _
        end
      end)

    keys = Enum.map(1..arity, &Macro.var(:"key#{&1}", __MODULE__))
    values = Enum.map(1..arity, &Macro.var(:"value#{&1}", __MODULE__))

    keys_and_values =
      Enum.map(1..arity, fn i ->
        quote do
          {
            unquote(Macro.var(:"key#{i}", __MODULE__)),
            unquote(Macro.var(:"value#{i}", __MODULE__))
          }
        end
      end)

    def map(unquote_splicing(heads_and_tails), func) do
      value = func.(unquote_splicing(heads))
      [value | map(unquote_splicing(tails), func)]
    end

    def map(unquote_splicing(empty_lists), _func) do
      []
    end

    def flat_map(unquote_splicing(heads_and_tails), func) do
      values = func.(unquote_splicing(heads))
      values ++ flat_map(unquote_splicing(tails), func)
    end

    def flat_map(unquote_splicing(empty_lists), _func) do
      []
    end

    def reduce(unquote_splicing(heads_and_tails), acc, func) do
      acc = func.(unquote_splicing(heads), acc)
      reduce(unquote_splicing(tails), acc, func)
    end

    def reduce(unquote_splicing(empty_lists), acc, _func) do
      acc
    end

    def flat_map_reduce(unquote_splicing(lists), acc, func) do
      flat_map_reduce2(unquote_splicing(lists), [], acc, func)
    end

    defp flat_map_reduce2(unquote_splicing(heads_and_tails), values, acc, func) do
      case func.(unquote_splicing(heads), acc) do
        {:halt, acc} ->
          flat_map_reduce2(unquote_splicing(empty_lists), values, acc, func)

        {values2, acc} ->
          flat_map_reduce2(unquote_splicing(tails), Enum.reverse(values2, values), acc, func)
      end
    end

    defp flat_map_reduce2(unquote_splicing(empty_lists), values, acc, _func) do
      {Enum.reverse(values), acc}
    end

    def map_reduce(unquote_splicing(lists), acc, func) do
      map_reduce2(unquote_splicing(lists), [], acc, func)
    end

    defp map_reduce2(unquote_splicing(heads_and_tails), values, acc, func) do
      {value, acc} = func.(unquote_splicing(heads), acc)
      map_reduce2(unquote_splicing(tails), [value | values], acc, func)
    end

    defp map_reduce2(unquote_splicing(empty_lists), values, acc, _func) do
      {Enum.reverse(values), acc}
    end

    def each(unquote_splicing(heads_and_tails), func) do
      func.(unquote_splicing(heads))
      each(unquote_splicing(tails), func)
    end

    def each(unquote_splicing(empty_lists), _func) do
      :ok
    end

    def zip(unquote_splicing(heads_and_tails)) do
      [{unquote_splicing(heads)} | zip(unquote_splicing(tails))]
    end

    def zip(unquote_splicing(empty_lists)) do
      []
    end

    def unzip([{unquote_splicing(underscores)} | _] = list) do
      unzip2(list, unquote_splicing(empty_lists))
    end

    defp unzip2([{unquote_splicing(heads)} | list], unquote_splicing(tails)) do
      unzip2(list, unquote_splicing(heads_and_tails))
    end

    defp unzip2([], unquote_splicing(lists)) do
      {unquote_splicing(reversed_lists)}
    end

    def transpose([unquote_splicing(heads_and_tails)]) do
      transpose2(unquote_splicing(heads_and_tails))
    end

    def transpose([unquote_splicing(empty_lists)]) do
      []
    end

    defp transpose2(unquote_splicing(heads_and_tails)) do
      [[unquote_splicing(heads)] | transpose2(unquote_splicing(tails))]
    end

    defp transpose2(unquote_splicing(empty_lists)) do
      []
    end

    def applicable?([unquote_splicing(underscores)]) do
      true
    end

    for arity2 <- arity..1 do
      values2 = Enum.map(1..arity2, &Macro.var(:"value#{&1}", __MODULE__))

      def split([unquote_splicing(values2) | suffix], unquote(arity)) do
        {[unquote_splicing(values2)], suffix}
      end
    end

    def take_opts(opts, [unquote_splicing(keys_and_values)]) do
      take_opts2(opts, unquote_splicing(keys), unquote_splicing(values))
    end

    for arity2 <- 1..arity do
      key = Macro.var(:"key#{arity2}", __MODULE__)
      value = Macro.var(:"value#{arity2}", __MODULE__)

      other_values =
        List.replace_at(values, arity2 - 1, quote do
          _
        end)

      defp take_opts2([{unquote(key), unquote(value)} | opts], unquote_splicing(keys), unquote_splicing(other_values)) do
        take_opts2(opts, unquote_splicing(keys), unquote_splicing(values))
      end
    end

    # defp take_opts2([{_, _} | opts], unquote_splicing(keys), unquote_splicing(values)) do
    #   take_opts2(opts, unquote_splicing(keys), unquote_splicing(values))
    # end

    defp take_opts2([], unquote_splicing(keys), unquote_splicing(values)) do
      [unquote_splicing(keys_and_values)]
    end
  end

  def applicable?(_) do
    false
  end

  def split([], _) do
    {[], []}
  end

  def split(list, 0) do
    {[], list}
  end

  def split(list, n) do
    Enum.split(list, n)
  end

  def max_arity do
    @max_arity
  end
end
