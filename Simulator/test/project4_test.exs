defmodule Project4Test do
  use ExUnit.Case
  doctest Project4

  test "greets the world" do
    assert Project4.hello() == :world
  end

  test "checking zipf distribution" do
    totalClients = 100
    Enum.map(1..totalClients,
    fn(i)->
      followers = Float.round(totalClients * (1/i))

      if followers == totalClients do
        followers = followers - 1
      end
      IO.puts "#{i} has #{followers}"
    end)
  end
end
