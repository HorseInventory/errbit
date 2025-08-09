describe UserDestroy do
  let(:app) do
    Fabricate(:app)
  end

  describe "#destroy" do
    let!(:user) { Fabricate(:user) }
    it 'should delete user' do
      expect do
        UserDestroy.new(user).destroy
      end.to change(User, :count)
    end
  end
end
