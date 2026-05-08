class UsersController < ApplicationController
  def index
    @users = User.order(:last_name, :first_name, :email)
  end
end
