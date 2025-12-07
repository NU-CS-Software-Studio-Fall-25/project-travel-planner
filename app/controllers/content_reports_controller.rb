# app/controllers/content_reports_controller.rb
class ContentReportsController < ApplicationController
  include Pagy::Backend

  before_action :require_login
  before_action :set_reportable, only: [ :new, :create ]

  def index
    @pagy, @reports = pagy(current_user.content_reports.recent, items: 20)
  end

  def new
    @report = ContentReport.new
  end

  def create
    @report = current_user.content_reports.build(report_params)
    @report.reportable = @reportable

    respond_to do |format|
      if @report.save
        format.html { redirect_to request.referer || root_path, notice: "Content has been reported. Thank you for helping keep our community safe." }
        format.json { render json: { success: true, message: "Content reported successfully" }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @report.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_reportable
    reportable_type = params[:reportable_type]
    reportable_id = params[:reportable_id]

    @reportable = case reportable_type
    when "TravelPlan"
      TravelPlan.find(reportable_id)
    when "Recommendation"
      Recommendation.find(reportable_id)
    else
      nil
    end

    unless @reportable
      redirect_to root_path, alert: "Invalid content type"
    end
  end

  def report_params
    params.require(:content_report).permit(:reason, :report_type)
  end
end
