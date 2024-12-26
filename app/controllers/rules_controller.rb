class RulesController < ApplicationController

  expose(:apps) do
    App.all.to_a.sort.map { |app| AppDecorator.new(app) }
  end

  expose(:rule)

  expose(:rules) do
    Rule.all.to_a.sort.map { |rule| RuleDecorator.new(rule) }
  end

  expose(:rule_decorate) do
    RuleDecorator.new(rule)
  end

  def index; end

  def show; end

  def new; end

  def create
    # @rule = Rule.new(rule_params)
    if rule.save
      flash[:success] = "#{I18n.t('controllers.rules.flash.rule_creation_success')}."
      redirect_to rules_path
    else
      render :new
    end
  end

  def edit; end

  def update
    if rule.update(rule_params)
      redirect_to rules_path, notice: "#{I18n.t('controllers.rules.flash.rule_update_success')}."
    else
      render :edit
    end
  end

  def destroy
    rule.destroy
    redirect_to rules_path, notice: "#{I18n.t('controllers.rules.flash.rule_delete_success')}."
  end

private

  def rule_params
    params.require(:rule).permit(:name, :condition, :app_id)
  end
end
