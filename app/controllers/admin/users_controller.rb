# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    def index
      @users = User.includes(:company, :quotes, :jobs)
                   .order(created_at: :desc)
    end

    def show
      @user = User.includes(:company, :quotes, :jobs).find(params[:id])
    end
  end
end
