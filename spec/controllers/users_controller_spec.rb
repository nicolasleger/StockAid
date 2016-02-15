require "rails_helper"

describe UsersController, type: :controller do
  let(:root) { users(:root) }
  let(:acme_root) { users(:acme_root) }
  let(:acme_normal) { users(:acme_normal) }
  let(:foo_inc_root) { users(:foo_inc_root) }
  let(:foo_inc_normal) { users(:foo_inc_normal) }

  let(:acme) { organizations(:acme) }

  def create_user(options)
    user = User.create! name: "Temporary User",
                        phone_number: "(408) 543-5432",
                        address: "334 Broadway, Campbell, CA",
                        email: "temp_user@stockaid-temp-domain.com",
                        password: "password",
                        role: "none"
    OrganizationUser.create! organization: options[:at], user: user, role: options[:role]
    user
  end

  describe "GET index" do
    it "is not allowed for normal users" do
      expect do
        signed_in_user :acme_normal
        get :index
      end.to raise_error(PermissionError)
    end

    it "shows all users for super admin" do
      signed_in_user :root
      get :index
      expect(assigns(:users)).to include(root, acme_root, acme_normal, foo_inc_root, foo_inc_normal)
    end

    it "shows users that the user has access to" do
      signed_in_user :acme_root
      get :index
      expect(assigns(:users)).to include(acme_root, acme_normal)
      expect(assigns(:users)).to_not include(root, foo_inc_root, foo_inc_normal)
    end
  end

  describe "GET edit" do
    it "is allowed for normal users to edit themselves" do
      signed_in_user :acme_normal
      get :edit, id: acme_normal.id.to_s
      expect(assigns(:user)).to eq(acme_normal)
    end

    it "is allowed for admin users to edit other users at their organization" do
      signed_in_user :acme_root
      get :edit, id: acme_normal.id.to_s
      expect(assigns(:user)).to eq(acme_normal)
    end

    it "is allowed for admin users to edit other admin users at their organization" do
      acme_root_2 = create_user(at: acme, role: "admin")
      signed_in_user :acme_root
      get :edit, id: acme_root_2.id.to_s
      expect(assigns(:user)).to eq(acme_root_2)
    end

    it "is allowed for super admin users to edit normal users" do
      signed_in_user :root
      get :edit, id: acme_normal.id.to_s
      expect(assigns(:user)).to eq(acme_normal)
    end

    it "is allowed for super admin users to edit admin users" do
      signed_in_user :root
      get :edit, id: acme_root.id.to_s
      expect(assigns(:user)).to eq(acme_root)
    end

    it "is not allowed for normal users to edit another normal user" do
      expect do
        acme_normal_2 = create_user(at: acme, role: "none")
        signed_in_user :acme_normal
        get :edit, id: acme_normal_2.id.to_s
      end.to raise_error(PermissionError)
    end

    it "is not allowed for admin users to edit normal users at another organization" do
      expect do
        signed_in_user :acme_root
        get :edit, id: foo_inc_normal.id.to_s
      end.to raise_error(PermissionError)
    end

    it "is not allowed for admin users to edit admin users at another organization" do
      expect do
        signed_in_user :acme_root
        get :edit, id: foo_inc_root.id.to_s
      end.to raise_error(PermissionError)
    end
  end
end
