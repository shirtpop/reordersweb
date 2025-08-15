class ProjectsController < ApplicationController
  def index
    @projects = current_client.projects.active.includes(:products)
  end

  def show
    @project = current_client.projects.active.find(params[:id])
    @order = current_client.orders.new
  end
end
