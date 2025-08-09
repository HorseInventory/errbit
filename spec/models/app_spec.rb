describe App, type: 'model' do
  context "Attributes" do
    it { is_expected.to have_field(:_id).of_type(String) }
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_fields(:api_key, :asset_host, :repository_branch) }
    it { is_expected.to have_field(:email_at_notices).of_type(Array).with_default_value_of(Errbit::Config.email_at_notices) }
  end

  context 'validations' do
    it 'requires a name' do
      app = Fabricate.build(:app, name: nil)
      expect(app).to_not be_valid
      expect(app.errors[:name]).to include("can't be blank")
    end

    it 'requires unique names' do
      Fabricate(:app, name: 'Errbit')
      app = Fabricate.build(:app, name: 'Errbit')
      expect(app).to_not be_valid
      expect(app.errors[:name]).to include("has already been taken")
    end

    it 'requires unique api_keys' do
      Fabricate(:app, api_key: 'APIKEY')
      app = Fabricate.build(:app, api_key: 'APIKEY')
      expect(app).to_not be_valid
      expect(app.errors[:api_key]).to include("has already been taken")
    end
  end

  describe '<=>' do
    it 'is compared by unresolved count' do
      app_0 = stub_model(App, name: 'app', unresolved_count: 1, problem_count: 1)
      app_1 = stub_model(App, name: 'app', unresolved_count: 0, problem_count: 1)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it 'is compared by problem count' do
      app_0 = stub_model(App, name: 'app', unresolved_count: 0, problem_count: 1)
      app_1 = stub_model(App, name: 'app', unresolved_count: 0, problem_count: 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end

    it 'is compared by name' do
      app_0 = stub_model(App, name: 'app_0', unresolved_count: 0, problem_count: 0)
      app_1 = stub_model(App, name: 'app_1', unresolved_count: 0, problem_count: 0)

      expect(app_0).to be < app_1
      expect(app_1).to be > app_0
    end
  end

  context 'being created' do
    it 'generates a new api-key' do
      app = Fabricate.build(:app)
      expect(app.api_key).to be_nil
      app.save
      expect(app.api_key).to_not be_nil
    end

    it 'generates a correct api-key' do
      app = Fabricate(:app)
      expect(app.api_key).to match(/^[a-f0-9]{32}$/)
    end
  end

  context "copying attributes from existing app" do
    it "should only copy the necessary fields" do
      @app = Fabricate(:app, name: "app")
      @copy_app = Fabricate(:app, name: "copy_app")
      @app.copy_attributes_from(@copy_app.id)
      expect(@app.name).to eq "app"
    end
  end

  context "searching" do
    it 'finds the correct record' do
      found = Fabricate(:app, name: 'Foo')
      not_found = Fabricate(:app, name: 'Brr')
      expect(App.search("Foo").to_a).to include(found)
      expect(App.search("Foo").to_a).to_not include(not_found)
    end
  end
end
