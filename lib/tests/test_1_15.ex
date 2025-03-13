defmodule Test1 do
  @moduledoc false
  @doc """
    task 1
    An anagram is the result of rearranging the letters of a word
    to produce a new word (see wikipedia).

    Note: anagrams are case insensitive

    Complete the function to return true if the two arguments given
    are anagrams of each other;
    return false otherwise.

    ## Params

      - a, b: strings

    ## Examples

      anagram?("foefet", "toffee") === true
      anagram?("dumble", "bumble") === false
      anagram?("Buckethead", "DeathCubeK") === true
  """

  def anagram?(a, b) do
    a1 =
      a
      |> String.upcase()
      |> String.graphemes()
      |> Enum.sort()

    b1 =
      b
      |> String.upcase()
      |> String.graphemes()
      |> Enum.sort()

    a1 === b1
  end

  @doc """
    task 2
    Create a function named divisors/Divisors that takes an integer n > 1
    and returns an array with all of the integer's divisors
    (except for 1 and the number itself), from smallest to largest.
    If the number is prime return the string "n is prime"

  ## Params

      - n: Integer

  ## Examples

      divisors(12) # should return [2,3,4,6]
      divisors(25) # should return [5]
      divisors(13) # should return "13 is prime"
  """
  def divisors(2) do
    "2 is prime"
  end

  def divisors(a) do
    list = Enum.filter(2..(a - 1), fn x -> rem(a, x) == 0 end)

    if list == [] do
      "#{a} is prime"
    else
      list
    end
  end

  @doc """
    task 3
    Complete it so that passing in RGB decimal values will result
    in a hexadecimal representation being returned.
    Valid decimal values for RGB are 0 - 255.
    Any values that fall out of that range must be
    rounded to the closest valid value.

    Note: Your answer should always be 6 characters long,
    the shorthand with 3 will not work here.

  ## Params

      - a,b,c: Integer

  ## Examples

      rgb(1,2,3) == "010203"
      rgb(255,255,255) == "FFFFFF"
      rgb(255,255,300) == "FFFFFF"
      rgb(148,0,211) == "9400D3"
      rgb(212,53,12) == "D4350C"
      rgb(173,255,47) == "ADFF2F"
  """
  def rgb(a, b, c) do
    [a, b, c]
    |> Enum.map(&get_number/1)
    |> Enum.map(&get_color_code/1)
    |> List.to_string()
  end

  defp get_number(num) do
    if num < 0, do: 0, else: if(num > 255, do: 255, else: num)
  end

  defp get_color_code(num) do
    String.pad_leading(Integer.to_string(num, 16), 2, "0")
  end
end
