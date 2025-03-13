defmodule MySuperApp.Accounts.UserNotifier do
  import Swoosh.Email

  alias MySuperApp.Mailer
  require Logger

  @moduledoc false

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"MySuperApp", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  def deliver_post_published_notification(user, post) do
    email =
      new()
      |> to("oleksandr.chernyonkov@gmail.com")
      |> to(user.email)
      |> from("cayman_raw@ukr.net")
      |> subject("For #{user.email}. Post Published Notification")
      |> text_body("""
      Hi, #{user.username}(#{user.email})!

      Your new post with title "#{post.title}" has been published!

      You can see it on the published users page!

      Thank you for being a part of our community!
      """)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        "Mail successfully sent"

      {:error, reason} ->
        "Failed to send mail: #{inspect(reason)}"
    end
  end
end
