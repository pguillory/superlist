defmodule SuperListTest do
  import SuperList
  use ExUnit.Case, async: true

  test "map" do
    assert map([1, 2], [3, 4], &(&1 * &2)) == [3, 8]
  end

  test "reduce" do
    assert reduce([1, 2], [3, 4], 0, &(&1 * &2 + &3)) == 11
  end

  test "map_reduce" do
    assert map_reduce([1, 2], [3, 4], 0, &{&1 * &2, &1 * &2 + &3}) == {[3, 8], 11}
  end

  test "each" do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    assert each([1, 2], [3, 4], &Agent.update(agent, fn acc -> [{&1, &2} | acc] end)) == :ok
    assert Agent.get(agent, &Enum.reverse/1) == [{1, 3}, {2, 4}]
  end

  test "zip" do
    assert zip([1, 2]) == [{1}, {2}]
    assert zip([1, 2], [3, 4]) == [{1, 3}, {2, 4}]
    assert zip([1, 2], [3, 4], [5, 6]) == [{1, 3, 5}, {2, 4, 6}]
  end

  test "unzip" do
    assert unzip([{1}, {2}]) == {[1, 2]}
    assert unzip([{1, 3}, {2, 4}]) == {[1, 2], [3, 4]}
    assert unzip([{1, 3, 5}, {2, 4, 6}]) == {[1, 2], [3, 4], [5, 6]}
  end

  test "transpose" do
    assert transpose([[1, 3], [2, 4]]) == [[1, 2], [3, 4]]
  end

  test "take_opts" do
    assert take_opts([], a: 3) == [a: 3]
    assert take_opts([a: 1], a: 3) == [a: 1]

    assert take_opts([], a: 3, b: 4) == [a: 3, b: 4]
    assert take_opts([a: 1], a: 3, b: 4) == [a: 1, b: 4]
    assert take_opts([a: 1, b: 2], a: 3, b: 4) == [a: 1, b: 2]
  end

  test "take_opts rejects unexpected keys" do
    assert catch_error(take_opts([a: 1, b: 2], a: 3)) == :function_clause
  end

  test "applicable?" do
    assert applicable?([]) == false
    assert applicable?([1]) == true
    assert applicable?([1, 2]) == true
    assert applicable?([1, 2, 3]) == true
    assert applicable?(Enum.to_list(1..max_arity())) == true
    assert applicable?(Enum.to_list(1..(max_arity() + 1))) == false
  end
end
