# SuperList

The Enum and List modules are powerful tools for working with lists in Elixir,
but they generally are designed for manipulating a single list at a time.
Sometimes you need to iterate over multiple lists simultaneously. For
example, to merge two lists, taking the maximum value between the two at each
offset:

```elixir
Enum.zip(list1, list2)
|> Enum.map(fn {element1, element2} ->
  max(element1, element2)
end)
```

While this works, it is verbose and inefficient. The Enum.zip call creates
tuples that we immediately match and throw away. If you've attempted to
optimize similar code, you may have written something like:

```elixir
def max_of_lists([element1 | list1], [element2 | list2]) do
  [max(element1, element2) | max_of_lists(list1, list2)]
end

def max_of_lists([], []) do
  []
end
```

Don't clutter your codebase with ad-hoc iteration code like this! Write it
more cleanly with SuperList:

```elixir
SuperList.map(list1, list2, &max/2)
```

## So it's like Enum.zip_with, or what?

Yeah, these are equivalent both in semantics and performance:

```elixir
Enum.zip_with(list1, list2, func)
```

```elixir
SuperList.map(list1, list2, func)
```

However things change with 3+ lists. Enum supports variable numbers of
arguments by accepting a list with a variable number of elements, whereas
Superlist defines multiple implementations with variable arities.

```elixir
Enum.zip_with([list1, list2, list3], fn [element1, element2, element3] ->
  func.(element1, element2, element3)
end)
```

```elixir
SuperList.map(list1, list2, list3, func)
```
In the above example with 3 lists, SuperList is not only cleaner but about 3.8x faster.

## Supported functions

| Enum function | SuperList equivalent |
| --- | --- |
| Enum.each | SuperList.each |
| Enum.map | SuperList.map |
| Enum.map_reduce | SuperList.map_reduce |
| Enum.reduce | SuperList.reduce |
| Enum.unzip | SuperList.unzip |
| Enum.zip | SuperList.zip |

```elixir
SuperList.map(list1, func/1)
SuperList.map(list1, list2, func/2)
SuperList.map(list1, list2, list3, func/3)
# ...etc.
```

## Code generation

These optimizations are achieved using code generation. Implementations for
each function are defined accepting from 1 up to 25 lists. The upper limit
can be increased using a compile time setting.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `superlist` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:superlist, "~> 0.1.0"}
  ]
end
```
