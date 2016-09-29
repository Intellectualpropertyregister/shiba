class NotificationsController < ApplicationController
  before_action :set_notification, only: [:show]

  # GET /notifications
  # GET /notifications.json
  def index
      @q = Notification.ransack(params[:q])
      if params[:format] == "json"
        @notifications = @q.result.where(reviewed: false).order("created_at desc")
      else
        @notifications = @q.result.where(reviewed: false).order("created_at desc").page(params[:page]).per(50)
      end

      respond_to do |format|
        format.html
        format.json { render :json => @notifications }
      end
  end

  def create title, error_msg, error_code
    @notification = Notification.new(title: title, error_msg: error_msg, error_code: error_code, reviewed: false)
    respond_to do |format|
      if @notification.save
        format.html
        format.json { render :show, status: :created, location: @notification }
      end
    end
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
     @notification.update(reviewed: true)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notification
      @notification = Notification.find(params[:id])
    end

end
