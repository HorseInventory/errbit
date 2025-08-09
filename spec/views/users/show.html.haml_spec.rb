describe 'users/show.html.haml', type: 'view' do
  let(:user) do
    stub_model(User, created_at: Time.zone.now, email: "test@example.com")
  end

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:user).and_return(user)
  end
end
