defmodule MobilizonWeb.Schema.UserType do
  @moduledoc """
  Schema representation for User
  """
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias Mobilizon.Events
  alias MobilizonWeb.Resolvers.User
  import MobilizonWeb.Schema.Utils

  import_types(MobilizonWeb.Schema.SortType)

  @desc "A local user of Mobilizon"
  object :user do
    field(:id, non_null(:id), description: "The user's ID")
    field(:email, non_null(:string), description: "The user's email")

    field(:profiles, non_null(list_of(:person)),
      description: "The user's list of profiles (identities)"
    )

    field(:default_actor, :person, description: "The user's default actor")

    field(:confirmed_at, :datetime,
      description: "The datetime when the user was confirmed/activated"
    )

    field(:confirmation_sent_at, :datetime,
      description: "The datetime the last activation/confirmation token was sent"
    )

    field(:confirmation_token, :string, description: "The account activation/confirmation token")

    field(:reset_password_sent_at, :datetime,
      description: "The datetime last reset password email was sent"
    )

    field(:reset_password_token, :string,
      description: "The token sent when requesting password token"
    )

    field(:feed_tokens, list_of(:feed_token),
      resolve: dataloader(Events),
      description: "A list of the feed tokens for this user"
    )

    field(:role, :user_role, description: "The role for the user")

    field(:locale, :string, description: "The user's locale")

    field(:participations, list_of(:participant),
      description: "The list of participations this user has"
    ) do
      arg(:after_datetime, :datetime)
      arg(:before_datetime, :datetime)
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&User.user_participations/3)
    end

    field(:drafts, list_of(:event), description: "The list of draft events this user has created") do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&User.user_drafted_events/3)
    end
  end

  enum :user_role do
    value(:administrator)
    value(:moderator)
    value(:user)
  end

  @desc "Token"
  object :refreshed_token do
    field(:access_token, non_null(:string), description: "Generated access token")
    field(:refresh_token, non_null(:string), description: "Generated refreshed token")
  end

  @desc "Users list"
  object :users do
    field(:total, non_null(:integer), description: "Total elements")
    field(:elements, non_null(list_of(:user)), description: "User elements")
  end

  @desc "The list of possible options for the event's status"
  enum :sortable_user_field do
    value(:id)
  end

  object :user_queries do
    @desc "Get an user"
    field :user, :user do
      arg(:id, non_null(:id))
      resolve(&User.find_user/3)
    end

    @desc "Get the current user"
    field :logged_user, :user do
      resolve(&User.get_current_user/3)
    end

    @desc "List instance users"
    field :users, :users do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)

      arg(:sort, :sortable_user_field, default_value: :id)
      arg(:direction, :sort_direction, default_value: :desc)

      resolve(&User.list_and_count_users/3)
    end
  end

  object :user_mutations do
    @desc "Create an user"
    field :create_user, type: :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, :string)

      resolve(handle_errors(&User.create_user/3))
    end

    @desc "Validate an user after registration"
    field :validate_user, type: :login do
      arg(:token, non_null(:string))
      resolve(&User.validate_user/3)
    end

    @desc "Resend registration confirmation token"
    field :resend_confirmation_email, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string)
      resolve(&User.resend_confirmation_email/3)
    end

    @desc "Send a link through email to reset user password"
    field :send_reset_password, type: :string do
      arg(:email, non_null(:string))
      arg(:locale, :string)
      resolve(&User.send_reset_password/3)
    end

    @desc "Reset user password"
    field :reset_password, type: :login do
      arg(:token, non_null(:string))
      arg(:password, non_null(:string))
      arg(:locale, :string, default_value: "en")
      resolve(&User.reset_password/3)
    end

    @desc "Login an user"
    field :login, type: :login do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&User.login_user/3)
    end

    @desc "Refresh a token"
    field :refresh_token, type: :refreshed_token do
      arg(:refresh_token, non_null(:string))
      resolve(&User.refresh_token/3)
    end

    @desc "Change default actor for user"
    field :change_default_actor, :user do
      arg(:preferred_username, non_null(:string))
      resolve(&User.change_default_actor/3)
    end

    @desc "Change an user password"
    field :change_password, :user do
      arg(:old_password, non_null(:string))
      arg(:new_password, non_null(:string))
      resolve(&User.change_password/3)
    end
  end
end
