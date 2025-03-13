defmodule MySuperApp.SendPostPublicationJob do
  use Oban.Worker, queue: :publication, max_attempts: 3

  @moduledoc false

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"post_id" => post_id}}) do
    post = MySuperApp.Blog.get_post(post_id)

    if post.user do
      MySuperApp.Accounts.UserNotifier.deliver_post_published_notification(post.user, post)
    end

    :ok
  end
end
