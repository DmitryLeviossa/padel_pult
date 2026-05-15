class UsersController < ApplicationController
  def index
    @q = User.ransack(params[:q])
    @users = @q.result.includes(:leagues).order(:last_name, :first_name, :email)
  end
end
