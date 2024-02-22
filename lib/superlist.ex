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

    def map(unquote_splicing(heads_and_tails), func) do
      value = func.(unquote_splicing(heads))
      [value | map(unquote_splicing(tails), func)]
    end

    def map(unquote_splicing(empty_lists), _func) do
      []
    end

    def reduce(unquote_splicing(heads_and_tails), acc, func) do
      acc = func.(unquote_splicing(heads), acc)
      reduce(unquote_splicing(tails), acc, func)
    end

    def reduce(unquote_splicing(empty_lists), acc, _func) do
      acc
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

    def transpose(unquote_splicing(heads_and_tails)) do
      [[unquote_splicing(heads)] | transpose(unquote_splicing(tails))]
    end

    def transpose(unquote_splicing(empty_lists)) do
      []
    end

    def applicable?([unquote_splicing(underscores)]) do
      true
    end
  end

  def applicable?(_) do
    false
  end

  def max_arity do
    @max_arity
  end
end
