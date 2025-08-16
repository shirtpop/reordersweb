json.projects @projects do |project|
  json.id project.id
  json.name project.name
  json.price_info project.price_info
end