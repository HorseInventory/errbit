describe User do
  context 'validations' do
    it 'require that a name is present' do
      user = Fabricate.build(:user, name: nil)
      expect(user).to_not be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end
    it "disables validations when reset password" do
      user = Fabricate.build(:user, email: '')
      user.save(validate: false)
      expect(user.reset_password('Password123', 'Password123')).to be_truthy
    end

    it 'should require a password with minimum of 6 characters' do
      user = Fabricate.build(:user)
      user.reset_password('12345', '12345')
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)", "is too short (minimum is 6 characters)")
    end
  end

  context "First user" do
    it "should be created this admin access via db:seed" do
      expect do
        allow($stdout).to receive(:puts).and_return(true)
        require Rails.root.join('db/seeds.rb')
      end.to change {
        User.where(admin: true).count
      }.from(0).to(1)
    end
  end
end
