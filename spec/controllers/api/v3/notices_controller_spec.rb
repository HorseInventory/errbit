describe Api::V3::NoticesController, type: :controller do
  let(:app) { Fabricate(:app) }
  let(:project_id) { app.api_key }
  let(:legit_params) { { project_id: project_id, key: project_id } }
  let(:legit_body) do
    Rails.root.join("spec/fixtures/api_v3_request.json").read
  end

  it 'sets CORS headers on POST request' do
    post :create, params: { project_id: 'invalid id' }
    expect(response.headers['Access-Control-Allow-Origin']).to(eq('*'))
    expect(response.headers['Access-Control-Allow-Headers']).to(eq('origin, content-type, accept'))
  end

  it 'responds to an OPTIONS request' do
    process :create, method: 'OPTIONS', params: { project_id: 'nothingspecial' }
    expect(response.headers['Access-Control-Allow-Origin']).to(eq('*'))
    expect(response.headers['Access-Control-Allow-Headers']).to(eq('origin, content-type, accept'))
  end

  it 'returns created notice id in json format' do
    post :create, body: legit_body, params: { **legit_params }
    notice = Notice.last
    expect(JSON.parse(response.body)).to(eq(
      'id'  => notice.id.to_s,
      'url' => notice.problem.url,
    ))
  end

  it 'responds with 201 created on success' do
    post :create, body: legit_body, params: { **legit_params }
    expect(JSON.parse(response.body)["error"]).to(be_nil)
    expect(response.status).to(be(201))
  end

  it 'responds with 201 created on success with token in Airbrake Token header' do
    request.headers['X-Airbrake-Token'] = project_id
    post :create, body: legit_body, params: { project_id: 123 }
    expect(response.status).to(be(201))
  end

  it 'responds with 201 created on success with token in Authorization header' do
    request.headers['Authorization'] = "Bearer #{project_id}"
    post :create, body: legit_body, params: { project_id: 123 }
    expect(response.status).to(be(201))
  end

  it 'responds with 422 when Authorization header is not valid' do
    request.headers['Authorization'] = "incorrect"
    post :create, body: legit_body, params: { project_id: 123 }
    expect(response.status).to(be(422))
  end

  it 'responds with 400 when request attributes are not valid' do
    allow_any_instance_of(AirbrakeApi::V3::NoticeParser).
      to(receive(:report).and_raise(AirbrakeApi::ParamsError))
    post :create, params: { project_id: 'ID' }
    expect(response.status).to(eq(400))
    expect(JSON.parse(response.body)["error"]).to(eq('Invalid request'))
  end

  it 'responds with 422 when project_id is invalid' do
    bad_key = 'wha?'
    post :create, body: legit_body, params: { project_id: 'hm?', key: bad_key }

    expect(response.status).to(eq(422))
    expect(JSON.parse(response.body)["error"]).to(eq("Invalid api_key: #{bad_key}"))
  end
end
