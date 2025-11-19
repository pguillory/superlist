defmodule SuperList do
  @moduledoc """
  Efficient operations over multiple lists simultaneously.

  The SuperList module provides optimized functions for working with multiple
  lists at once, similar to how `Enum` and `List` work with single lists.
  Instead of zipping lists together and then mapping over tuples, SuperList
  allows you to pass multiple lists directly to functions like `map/3`,
  `reduce/4`, etc.

  ## Performance

  SuperList uses compile-time code generation to create specialized implementations
  for each arity (number of lists), avoiding the overhead of creating intermediate
  tuples. This makes operations on multiple lists both cleaner and faster.

  ## Examples

      iex> SuperList.map([1, 2, 3], [4, 5, 6], &+/2)
      [5, 7, 9]

      iex> SuperList.zip([1, 2], [3, 4], [5, 6])
      [{1, 3, 5}, {2, 4, 6}]

      iex> SuperList.reduce([1, 2], [3, 4], 0, &(&1 * &2 + &3))
      11
  """

  @max_arity Application.compile_env(:superlist, :max_arity, 25)

  for arity <- 1..@max_arity//1 do
    heads = Enum.map(1..arity//1, &Macro.var(:"head#{&1}", __MODULE__))
    tails = Enum.map(1..arity//1, &Macro.var(:"tail#{&1}", __MODULE__))
    lists = Enum.map(1..arity//1, &Macro.var(:"list#{&1}", __MODULE__))

    heads_and_tails =
      Enum.map(1..arity//1, fn i ->
        quote do
          [
            unquote(Macro.var(:"head#{i}", __MODULE__))
            | unquote(Macro.var(:"tail#{i}", __MODULE__))
          ]
        end
      end)

    reversed_lists =
      Enum.map(1..arity//1, fn i ->
        quote do
          Enum.reverse(unquote(Macro.var(:"list#{i}", __MODULE__)))
        end
      end)

    reversed_flattened_lists =
      Enum.map(1..arity//1, fn i ->
        quote do
          Enum.reverse(unquote(Macro.var(:"list#{i}", __MODULE__)))
          |> Enum.concat()
        end
      end)

    empty_lists =
      Enum.map(1..arity//1, fn _ ->
        quote do
          []
        end
      end)

    underscores =
      Enum.map(1..arity//1, fn _ ->
        quote do
          _
        end
      end)

    keys = Enum.map(1..arity//1, &Macro.var(:"key#{&1}", __MODULE__))
    values = Enum.map(1..arity//1, &Macro.var(:"value#{&1}", __MODULE__))

    keys_and_values =
      Enum.map(1..arity//1, fn i ->
        quote do
          {
            unquote(Macro.var(:"key#{i}", __MODULE__)),
            unquote(Macro.var(:"value#{i}", __MODULE__))
          }
        end
      end)

    example_lists =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..3, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_params = Enum.map_join(1..arity, ", ", &"a#{&1}")
    example_sum = Enum.map_join(1..arity, " + ", &"a#{&1}")

    example_result_nums =
      Enum.map(1..3, fn j -> Enum.sum(Enum.map(1..arity, &(&1 + (j - 1) * 10))) end)

    @doc """
    Maps over #{arity} #{if arity == 1, do: "list", else: "lists simultaneously"}, applying the given function to
    corresponding elements from each list.

    The function receives #{arity} #{if arity == 1, do: "element", else: "elements (one from each list)"} and returns a single value.
    The result is a list of transformed values. Iteration stops when any list
    is exhausted.

    ## Examples

        iex> SuperList.map(#{Enum.join(example_lists, ", ")}, fn #{example_params} -> #{example_sum} end)
        [#{Enum.join(example_result_nums, ", ")}]

    """

    def map(unquote_splicing(heads_and_tails), func) do
      value = func.(unquote_splicing(heads))
      [value | map(unquote_splicing(tails), func)]
    end

    def map(unquote_splicing(empty_lists), _func) do
      []
    end

    if arity == 1 do
      @doc """
      Maps and flattens in one pass over multiple lists simultaneously.

      Similar to `map/3` but the given function should return a list for each
      set of elements, and all returned lists are concatenated into a single result.

      ## Examples

          iex> SuperList.flat_map([1, 2], [3, 4], fn a, b -> [a, b] end)
          [1, 3, 2, 4]

          iex> SuperList.flat_map([1, 2], [10, 20], fn a, b -> [a * b] end)
          [10, 40]

      """
    end

    def flat_map(unquote_splicing(heads_and_tails), func) do
      values = func.(unquote_splicing(heads))
      values ++ flat_map(unquote_splicing(tails), func)
    end

    def flat_map(unquote_splicing(empty_lists), _func) do
      []
    end

    example_lists_reduce =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..2, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_params_reduce = Enum.map_join(1..arity, ", ", &"a#{&1}")
    example_sum_expr = Enum.map_join(1..arity, " + ", &"a#{&1}")

    example_result =
      Enum.sum(Enum.map(1..arity, fn i -> Enum.sum(Enum.map(1..2, &(&1 + (i - 1) * 10))) end))

    @doc """
    Reduces #{arity} #{if arity == 1, do: "list", else: "lists simultaneously"} into a single accumulated value.

    The given function receives #{arity} #{if arity == 1, do: "element", else: "elements (one from each list)"} plus the accumulator,
    and returns the new accumulator value. Iteration continues until any list
    is exhausted.

    ## Examples

        iex> SuperList.reduce(#{Enum.join(example_lists_reduce, ", ")}, 0, fn #{example_params_reduce}, acc -> #{example_sum_expr} + acc end)
        #{example_result}

    """

    def reduce(unquote_splicing(heads_and_tails), acc, func) do
      acc = func.(unquote_splicing(heads), acc)
      reduce(unquote_splicing(tails), acc, func)
    end

    def reduce(unquote_splicing(empty_lists), acc, _func) do
      acc
    end

    example_lists_fmr =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..3, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_params_fmr = Enum.map_join(1..arity, ", ", &"a#{&1}")
    example_sum_expr_fmr = Enum.map_join(1..arity, " + ", &"a#{&1}")

    example_result_nums_fmr =
      Enum.map(1..3, fn j -> Enum.sum(Enum.map(1..arity, &(&1 + (j - 1) * 10))) end)

    @doc """
    Maps and flattens while reducing over #{arity} #{if arity == 1, do: "list", else: "lists simultaneously"}.

    Similar to `Enum.flat_map_reduce/3` but works with #{arity} #{if arity == 1, do: "list", else: "lists"}. The function
    should return either `{:halt, acc}` to stop iteration early, or `{list, acc}`
    where `list` is a list of values to include in the result.

    Returns a tuple of `{flattened_list, final_acc}`.

    ## Examples

        iex> SuperList.flat_map_reduce(#{Enum.join(example_lists_fmr, ", ")}, 0, fn #{example_params_fmr}, acc ->
        ...>   {[#{example_sum_expr_fmr}], acc + 1}
        ...> end)
        {[#{Enum.join(example_result_nums_fmr, ", ")}], 3}

    """

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

    example_lists_mr =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..2, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_params_mr = Enum.map_join(1..arity, ", ", &"a#{&1}")
    example_sum_expr_mr = Enum.map_join(1..arity, " + ", &"a#{&1}")

    example_result_nums_mr =
      Enum.map(1..2, fn j -> Enum.sum(Enum.map(1..arity, &(&1 + (j - 1) * 10))) end)

    @doc """
    Maps while reducing over #{arity} #{if arity == 1, do: "list", else: "lists simultaneously"}.

    Similar to `Enum.map_reduce/3` but works with #{arity} #{if arity == 1, do: "list", else: "lists"}. The function
    receives #{arity} #{if arity == 1, do: "element", else: "elements (one from each list)"} plus the accumulator, and returns a
    tuple `{value, new_acc}`.

    Returns a tuple of `{mapped_list, final_acc}`.

    ## Examples

        iex> SuperList.map_reduce(#{Enum.join(example_lists_mr, ", ")}, 0, fn #{example_params_mr}, acc ->
        ...>   {#{example_sum_expr_mr}, acc + 1}
        ...> end)
        {[#{Enum.join(example_result_nums_mr, ", ")}], 2}

    """

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

    example_lists_each =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..2, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_params_each = Enum.map_join(1..arity, ", ", &"a#{&1}")
    example_sum_expr_each = Enum.map_join(1..arity, " + ", &"a#{&1}")

    @doc """
    Iterates over #{arity} #{if arity == 1, do: "list", else: "lists simultaneously"}, invoking the function for side effects.

    The function receives #{arity} #{if arity == 1, do: "element", else: "elements (one from each list)"}. Iteration continues until
    any list is exhausted. Returns `:ok`.

    ## Examples

        iex> SuperList.each(#{Enum.join(example_lists_each, ", ")}, fn #{example_params_each} -> IO.puts(#{example_sum_expr_each}) end)
        :ok

    """

    def each(unquote_splicing(heads_and_tails), func) do
      func.(unquote_splicing(heads))
      each(unquote_splicing(tails), func)
    end

    def each(unquote_splicing(empty_lists), _func) do
      :ok
    end

    example_lists_zip =
      Enum.map(1..arity, fn i -> "[#{Enum.join(Enum.map(1..2, &(&1 + (i - 1) * 10)), ", ")}]" end)

    example_tuple_elements =
      Enum.map(1..2, fn j ->
        "{#{Enum.map_join(1..arity, ", ", fn i -> j + (i - 1) * 10 end)}}"
      end)

    @doc """
    Zips #{arity} #{if arity == 1, do: "list", else: "lists"} into a list of #{arity}-tuples.

    Takes corresponding elements from each list and combines them into #{arity}-element tuples.
    The resulting list is as long as the shortest input list.

    ## Examples

        iex> SuperList.zip(#{Enum.join(example_lists_zip, ", ")})
        [#{Enum.join(example_tuple_elements, ", ")}]

    """

    def zip(unquote_splicing(heads_and_tails)) do
      [{unquote_splicing(heads)} | zip(unquote_splicing(tails))]
    end

    def zip(unquote_splicing(empty_lists)) do
      []
    end

    if arity == 1 do
      @doc """
      Unzips a list of tuples into a tuple of lists.

      Takes a list of n-element tuples and returns an n-tuple of lists, where
      each list contains the elements from the corresponding position in the tuples.

      ## Examples

          iex> SuperList.unzip([{1, 3}, {2, 4}])
          {[1, 2], [3, 4]}

          iex> SuperList.unzip([{1, 3, 5}, {2, 4, 6}])
          {[1, 2], [3, 4], [5, 6]}

      """
    end

    def unzip([{unquote_splicing(underscores)} | _] = list) do
      unzip(list, unquote_splicing(empty_lists))
    end

    defp unzip([{unquote_splicing(heads)} | list], unquote_splicing(tails)) do
      unzip(list, unquote_splicing(heads_and_tails))
    end

    defp unzip([], unquote_splicing(lists)) do
      {unquote_splicing(reversed_lists)}
    end

    if arity == 1 do
      @doc """
      Unzips a list of tuples containing lists into a tuple of flattened lists.

      Similar to `unzip/1`, but when each element of the tuple is a list, those
      lists are flattened in the resulting output.

      ## Examples

          iex> SuperList.flat_unzip([{[1, 2], [5, 6]}, {[3, 4], [7, 8]}])
          {[1, 2, 3, 4], [5, 6, 7, 8]}

      """
    end

    def flat_unzip([{unquote_splicing(underscores)} | _] = list) do
      flat_unzip(list, unquote_splicing(empty_lists))
    end

    defp flat_unzip([{unquote_splicing(heads)} | list], unquote_splicing(tails)) do
      flat_unzip(list, unquote_splicing(heads_and_tails))
    end

    defp flat_unzip([], unquote_splicing(lists)) do
      {unquote_splicing(reversed_flattened_lists)}
    end

    if arity == 1 do
      @doc """
      Transposes a list of lists, converting rows to columns.

      Takes a list containing N lists and returns a list where the first element
      contains all first elements, the second element contains all second elements,
      and so on.

      ## Examples

          iex> SuperList.transpose([[1, 2, 3], [4, 5, 6]])
          [[1, 4], [2, 5], [3, 6]]

          iex> SuperList.transpose([[1, 2], [3, 4], [5, 6]])
          [[1, 3, 5], [2, 4, 6]]

      """
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

    if arity == 1 do
      @doc """
      Checks if a list can be processed by the Superlist generated functions.

      ## Examples

          iex> SuperList.applicable?([1, 2])
          true

          iex> SuperList.applicable?([1, 2, 3])
          true

          iex> SuperList.applicable?(:not_a_list)
          false

      """
    end

    def applicable?([unquote_splicing(underscores)]) do
      true
    end

    for arity2 <- arity..1//-1 do
      values2 = Enum.map(1..arity2//1, &Macro.var(:"value#{&1}", __MODULE__))

      if arity == 1 and arity2 == 1 do
        @doc """
        Splits a list at the given position.

        Returns a tuple where the first element is a list of the first N elements,
        and the second element is the rest of the list.

        ## Examples

            iex> SuperList.split([1, 2, 3, 4], 2)
            {[1, 2], [3, 4]}

            iex> SuperList.split([1, 2, 3], 0)
            {[], [1, 2, 3]}

        """
      end

      def split([unquote_splicing(values2) | suffix], unquote(arity)) do
        {[unquote_splicing(values2)], suffix}
      end
    end

    if arity == 1 do
      @doc """
      Extracts specific keys from a keyword list using a template.

      Takes a keyword list and a template list of key-value pairs. Returns a new
      keyword list with only the specified keys, using values from the input opts
      when present, otherwise using the default values from the template.

      ## Examples

          iex> SuperList.take_opts([a: 1, b: 2, c: 3], [a: 0, c: 0])
          [a: 1, c: 3]

          iex> SuperList.take_opts([a: 1], [a: 0, b: 99])
          [a: 1, b: 99]

      """
    end

    def take_opts(opts, [unquote_splicing(keys_and_values)]) do
      take_opts2(opts, unquote_splicing(keys), unquote_splicing(values))
    end

    for arity2 <- 1..arity//1 do
      key = Macro.var(:"key#{arity2}", __MODULE__)
      value = Macro.var(:"value#{arity2}", __MODULE__)

      other_values =
        List.replace_at(
          values,
          arity2 - 1,
          quote do
            _
          end
        )

      defp take_opts2(
             [{unquote(key), unquote(value)} | opts],
             unquote_splicing(keys),
             unquote_splicing(other_values)
           ) do
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

  @doc """
  Returns the maximum arity (number of lists) supported by SuperList functions.

  This value is set at compile time via the `:max_arity` configuration option,
  with a default of 25.

  ## Examples

      iex> SuperList.max_arity()
      25

  """
  def max_arity do
    @max_arity
  end
end
