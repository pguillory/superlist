list = Enum.to_list(1..100)

Benchee.run(%{
  "SuperList.split" => fn ->
    SuperList.split(list, 5)
  end,
  "Enum.split" => fn ->
    Enum.split(list, 5)
  end
})
