json.clients @clients do |client|
  json.id client.id
  json.company_name client.company_name
  json.personal_name client.personal_name
end