module AppsHelper
  def link_to_copy_attributes_from_other_app
    return if App.count <= 1

    html = link_to('copy settings from another app', '#',
      class: 'button copy_config')
    html << select("duplicate", "app",
      App.all.asc(:name).reject { |a| a == @app }.
      collect { |p| [p.name, p.id] }, { include_blank: "[choose app]" },
      class: "choose_other_app", style: "display: none;")
    html
  end
end
