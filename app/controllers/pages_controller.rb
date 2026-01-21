# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_company
  layout "landing"

  def home
    # Redirect logged-in users to dashboard
    redirect_to dashboard_path if user_signed_in?
  end

  def privacy
  end

  def terms
  end
end
