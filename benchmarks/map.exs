list1 = Enum.to_list(1..10_000)
list2 = Enum.to_list(1..10_000)
list3 = Enum.to_list(1..10_000)

Benchee.run(%{
  "SuperList.map" => fn ->
    SuperList.map(list1, list2, list3, &(&1 + &2 + &3))
  end,
  "Enum.zip_with" => fn ->
    Enum.zip_with([list1, list2, list3], fn [v1, v2, v3] -> v1 + v2 + v3 end)
  end
})
