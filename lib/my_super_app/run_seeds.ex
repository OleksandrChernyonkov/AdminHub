defmodule MySuperApp.RunSeeds do
  alias MySuperApp.{Repo, Phone, Room, Accounts, CasinosAdmins, Blog}
  alias Faker.{Internet, Person}
  @moduledoc false

  def run_seeds() do
    rooms_with_phones = %{
      "301" => ["0991122301", "0993344301"],
      "302" => ["0990000302", "0991111302"],
      "303" => ["0992222303"],
      "304" => ["0993333304", "0994444304"],
      "305" => ["0935555305", "09306666305", "0937777305"]
    }

    Repo.transaction(fn ->
      rooms_with_phones
      |> Enum.each(fn {room, phones} ->
        %Room{}
        |> Room.changeset(%{room_number: room})
        |> Ecto.Changeset.put_assoc(
          :phones,
          phones
          |> Enum.map(
            &(%Phone{}
              |> Phone.changeset(%{phone_number: &1}))
          )
        )
        |> Repo.insert!()
      end)

      Repo.insert_all(
        Room,
        [
          %{room_number: 666},
          %{room_number: 1408},
          %{room_number: 237}
        ]
      )

      Repo.insert_all(
        Phone,
        [
          %{phone_number: "380661112233"},
          %{phone_number: "380669997788"},
          %{phone_number: "380665554466"}
        ]
      )

      Repo.insert_all(
        "left_menu",
        [
          %{id: 1, title: "Vision"},
          %{id: 2, title: "Getting started"},
          %{id: 3, title: "How to contribute?"},
          %{id: 4, title: "Colours"},
          %{id: 5, title: "Tokens"},
          %{id: 6, title: "Transform SVG"},
          %{id: 7, title: "Manifest"},
          %{id: 8, title: "Tailwind"}
        ]
      )

      Repo.insert_all(
        "right_menu",
        [
          %{id: 1, title: "Vision"},
          %{id: 2, title: "Getting started"},
          %{id: 3, title: "How to contribute?"},
          %{id: 4, title: "Colours"},
          %{id: 5, title: "Tokens"},
          %{id: 6, title: "Transform SVG"},
          %{id: 7, title: "Manifest"},
          %{id: 8, title: "Tailwind"}
        ]
      )
    end)

    CasinosAdmins.create_operator(%{name: "test_operator"})
    CasinosAdmins.create_operator(%{name: "second_operator"})
    CasinosAdmins.create_operator(%{name: "third_operator"})

    CasinosAdmins.create_permission(%{name: "read_only"})
    CasinosAdmins.create_permission(%{name: "admin"})
    CasinosAdmins.create_permission(%{name: "operator"})
    CasinosAdmins.create_permission(%{name: "super_admin"})

    # 1
    CasinosAdmins.create_role(%{name: "user", operator_id: nil, permission_id: nil})
    # 2
    CasinosAdmins.create_role(%{name: "super_admin", operator_id: nil, permission_id: 4})
    # 3
    CasinosAdmins.create_role(%{name: "admin_operator1", operator_id: 1, permission_id: 3})
    # 4
    CasinosAdmins.create_role(%{name: "admin_operator2", operator_id: 2, permission_id: 3})
    # 5
    CasinosAdmins.create_role(%{name: "admin_operator3", operator_id: 3, permission_id: 3})
    # 6
    CasinosAdmins.create_role(%{name: "admin1", operator_id: 1, permission_id: 2})
    # 7
    CasinosAdmins.create_role(%{name: "admin2", operator_id: 2, permission_id: 2})
    # 8
    CasinosAdmins.create_role(%{name: "admin3", operator_id: 3, permission_id: 2})
    # 9
    CasinosAdmins.create_role(%{name: "read_only_admin1", operator_id: 1, permission_id: 1})
    # 10
    CasinosAdmins.create_role(%{name: "read_only_admin2", operator_id: 2, permission_id: 1})
    # 11
    CasinosAdmins.create_role(%{name: "read_only_admin3", operator_id: 3, permission_id: 1})

    Accounts.register_user(%{
      username: "superadmin",
      email: "superadmin@gmail.com",
      password: "qwerty123",
      role_id: 2,
      operator_id: nil
    })

    Enum.each([3, 6, 9], fn x ->
      username = Internet.user_name()

      Accounts.register_user(%{
        email: username <> "@gmail.com",
        username: username,
        password: "qwerty123",
        role_id: x,
        operator_id: 1
      })
    end)

    Enum.each([4, 7, 10], fn x ->
      username = Internet.user_name()

      Accounts.register_user(%{
        email: username <> "@gmail.com",
        username: username,
        password: "qwerty123",
        role_id: x,
        operator_id: 2
      })
    end)

    Enum.each([5, 8, 11], fn x ->
      username = Internet.user_name()

      Accounts.register_user(%{
        email: username <> "@gmail.com",
        username: username,
        password: "qwerty123",
        role_id: x,
        operator_id: 3
      })
    end)

    Enum.each(1..20, fn _x ->
      name = Person.last_name()

      Accounts.register_user(%{
        username: name,
        email: name <> "@gmail.com",
        password: "qwerty123",
        operator_id: Enum.random([1, 2, 3]),
        role_id: 1
      })
    end)

    CasinosAdmins.create_site(%{brand: "JoyCasino", operator_id: 1})
    CasinosAdmins.create_site(%{brand: "SlotCasino", operator_id: 2})
    CasinosAdmins.create_site(%{brand: "CasinoBet", operator_id: 3})

    tag_names = ["Weather", "Sport", "Economics", "Politics", "Lifestyle"]

    tags =
      Enum.map(tag_names, fn x -> Blog.create_tag(%{name: x}) end)
      |> Enum.map(fn {:ok, tag} -> tag end)

    Enum.map(1..40, fn x ->
      tag = Enum.random(tags)
      id = Enum.random(1..30)
      Blog.create_post(%{body: "Post #{x}", title: "Title #{x}", user_id: id, tags: [tag]})
    end)
  end
end
