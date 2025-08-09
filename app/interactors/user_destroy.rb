class UserDestroy
  def initialize(user)
    @user = user
  end

  def destroy
    @user.destroy
  end
end
