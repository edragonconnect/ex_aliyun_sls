defmodule ExAliyunSls.UtilsTest do
  use ExUnit.Case

  defmodule A do
    defstruct [:b]
  end

  defmodule B do
    defstruct [:field1, :field2]
  end

  test "iterate struct to map" do
    b1 = %ExAliyunSls.UtilsTest.B{field1: "field1", field2: "field2"}
    a1 = %ExAliyunSls.UtilsTest.A{b: b1}

    res = ExAliyunSls.Utils.iterate_struct_to_map(a1)
    assert res == %{b: %{field1: "field1", field2: "field2"}}

    a2 = %{"test_field1" => a1, "test_field2" => %{inner_field1: "1"}}
    res2 = ExAliyunSls.Utils.iterate_struct_to_map(a2)

    assert res2 == %{
             "test_field1" => %{b: %{field1: "field1", field2: "field2"}},
             "test_field2" => %{inner_field1: "1"}
           }

    a3 = %{"test1" => 1, "test2" => [a1, "item2"], "test3" => [field1: b1]}
    res3 = ExAliyunSls.Utils.iterate_struct_to_map(a3)

    assert res3 == %{
             "test1" => 1,
             "test2" => [%{b: %{field1: "field1", field2: "field2"}}, "item2"],
             "test3" => [field1: %{field1: "field1", field2: "field2"}]
           }

    res4 = ExAliyunSls.Utils.iterate_struct_to_map(b1)
    assert res4 == %{field1: "field1", field2: "field2"}
  end
end
